local encoder = require("opentelemetry.trace.exporter.encoder")
local pb = require("opentelemetry.trace.exporter.pb")
local otel_global = require("opentelemetry.global")
local util = require("opentelemetry.util")
local BACKOFF_RETRY_LIMIT = 3
local DEFAULT_TIMEOUT_MS = 10000
local exporter_request_duration_metric = "otel.otlp_exporter.request_duration"
local CIRCUIT_OPEN_THRESHOLD = 5
local RECLOSE_CIRCUIT_THRESHOLD = 5
local CIRCUIT_CLOSED = "closed"
local CIRCUIT_OPEN = "open"
local CIRCUIT_HALF_OPEN = "half_open"

local _M = {
}

local mt = {
    __index = _M
}

function _M.new(http_client, timeout_ms, circuit_reset_timeout_ms)
    local self = {
        client = http_client,
        timeout_ms = timeout_ms or DEFAULT_TIMEOUT_MS,
        failure_count = 0,
        success_count = 0,
        circuit_open_start_time_ms = nil,
        circuit_state = "open",
        circuit_reset_timeout_ms = circuit_reset_timeout_ms or 5000
    }
    return setmetatable(self, mt)
end

--------------------------------------------------------------------------------
-- Repeatedly make calls to collector until success, failure threshold or
-- timeout
--
-- @param exporter The exporter to use for the collector call
-- @param pb_encoded_body protobuf-encoded body to send to the collector
-- @return true if call succeeded; false if call failed
-- @return nil if call succeeded; error message string if call failed
--------------------------------------------------------------------------------
local function call_collector(exporter, pb_encoded_body)
    local start_time_ms = util.gettimeofday_ms()
    local failures = 0
    local res
    local res_error

    while failures < BACKOFF_RETRY_LIMIT do
        local current_time = util.gettimeofday_ms()
        if current_time - start_time_ms > exporter.timeout_ms then
            local err_message = "Collector retries timed out (timeout " .. exporter.timeout_ms .. ")"
            ngx.log(ngx.WARN, err_message)
            return false, err_message
        end


        -- If  failure count exceeds threshold, open circuit
        if exporter.failure_count >= CIRCUIT_OPEN_THRESHOLD then
            exporter.circuit_state = CIRCUIT_OPEN
            exporter.circuit_open_start_time_ms = current_time
        end

        -- If circuit is open, no requests should flow through
        if exporter.circuit_state == CIRCUIT_OPEN then
            -- If circuit is open, we should make half-open if reset timeout has elapsed
            if (current_time - exporter.circuit_open_start_time_ms) > exporter.circuit_reset_timeout_ms then
                exporter.circuit_state = CIRCUIT_HALF_OPEN
                exporter.circuit_open_start_time_ms = nil
                exporter.failure_count = 0
                exporter.success_count = 0
            else
                return false, "Circuit breaker is open"
            end
        end

        res, res_error = exporter.client:do_request(pb_encoded_body)
        local after_time = util.gettimeofday_ms()
        otel_global.metrics_reporter:record_value(
            exporter_request_duration_metric, after_time - current_time)

        if not res then
            exporter.failure_count = exporter.failure_count + 1
            if exporter.circuit_state == CIRCUIT_HALF_OPEN then
                exporter.circuit_state = CIRCUIT_OPEN
            end

            failures = failures + 1
            ngx.sleep(util.random_float(2 ^ failures))
            ngx.log(ngx.INFO, "Retrying call to collector (retry #" .. failures .. ")")
        else
            if exporter.circuit_state == CIRCUIT_HALF_OPEN then
                exporter.success_count = exporter.success_count + 1
                if exporter.success_count >= RECLOSE_CIRCUIT_THRESHOLD then
                    exporter.failure_count = 0
                    exporter.circuit_state = CIRCUIT_CLOSED
                end
            end
            return true, nil
        end
    end

    return false, res_error or "unknown"
end

function _M.export_spans(self, spans)
    assert(spans[1])

    local body = {
        resource_spans = {
            {
                resource = {
                    attributes = spans[1].tracer.provider.resource.attrs,
                    dropped_attributes_count = 0,
                },
                instrumentation_library_spans = {
                    {
                        instrumentation_library = {
                            name = spans[1].tracer.il.name,
                            version = spans[1].tracer.il.version,
                        },
                        spans = {}
                    },
                },
            }
        }
    }
    for _, span in ipairs(spans) do
        table.insert(
            body.resource_spans[1].instrumentation_library_spans[1].spans,
            encoder.for_otlp(span))
    end
    return call_collector(self, pb.encode(body))
end

function _M.shutdown(self)

end

return _M
