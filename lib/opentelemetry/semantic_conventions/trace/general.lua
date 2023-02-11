--- This file was automatically generated by utils/generate_semantic_conventions.lua
-- See: https://github.com/open-telemetry/opentelemetry-specification/tree/main/specification/trace/semantic_conventions
--
-- module @semantic_conventions.trace.general
local _M = {
    -- Transport protocol used. See note below.
    NET_TRANSPORT = "net.transport",
    -- Application layer protocol used. The value SHOULD be normalized to lowercase.
    NET_APP_PROTOCOL_NAME = "net.app.protocol.name",
    -- Version of the application layer protocol used. See note below.
    NET_APP_PROTOCOL_VERSION = "net.app.protocol.version",
    -- Remote socket peer name.
    NET_SOCK_PEER_NAME = "net.sock.peer.name",
    -- Remote socket peer address: IPv4 or IPv6 for internet protocols, path for local communication, [etc](https://man7.org/linux/man-pages/man7/address_families.7.html).
    NET_SOCK_PEER_ADDR = "net.sock.peer.addr",
    -- Remote socket peer port.
    NET_SOCK_PEER_PORT = "net.sock.peer.port",
    -- Protocol [address family](https://man7.org/linux/man-pages/man7/address_families.7.html) which is used for communication.
    NET_SOCK_FAMILY = "net.sock.family",
    -- Logical remote hostname, see note below.
    NET_PEER_NAME = "net.peer.name",
    -- Logical remote port number
    NET_PEER_PORT = "net.peer.port",
    -- Logical local hostname or similar, see note below.
    NET_HOST_NAME = "net.host.name",
    -- Logical local port number, preferably the one that the peer used to connect
    NET_HOST_PORT = "net.host.port",
    -- Local socket address. Useful in case of a multi-IP host.
    NET_SOCK_HOST_ADDR = "net.sock.host.addr",
    -- Local socket port number.
    NET_SOCK_HOST_PORT = "net.sock.host.port",
    -- The internet connection type currently being used by the host.
    NET_HOST_CONNECTION_TYPE = "net.host.connection.type",
    -- This describes more details regarding the connection.type. It may be the type of cell technology connection, but it could be used for describing details about a wifi connection.
    NET_HOST_CONNECTION_SUBTYPE = "net.host.connection.subtype",
    -- The name of the mobile carrier.
    NET_HOST_CARRIER_NAME = "net.host.carrier.name",
    -- The mobile carrier country code.
    NET_HOST_CARRIER_MCC = "net.host.carrier.mcc",
    -- The mobile carrier network code.
    NET_HOST_CARRIER_MNC = "net.host.carrier.mnc",
    -- The ISO 3166-1 alpha-2 2-character country code associated with the mobile carrier network.
    NET_HOST_CARRIER_ICC = "net.host.carrier.icc",
    -- The [`service.name`](../../resource/semantic_conventions/README.md#service) of the remote service. SHOULD be equal to the actual `service.name` resource attribute of the remote service if any.
    PEER_SERVICE = "peer.service",
    -- Username or client_id extracted from the access token or [Authorization](https://tools.ietf.org/html/rfc7235#section-4.2) header in the inbound request from outside the system.
    ENDUSER_ID = "enduser.id",
    -- Actual/assumed role the client is making the request under extracted from token or application security context.
    ENDUSER_ROLE = "enduser.role",
    -- Scopes or granted authorities the client currently possesses extracted from token or application security context. The value would come from the scope associated with an [OAuth 2.0 Access Token](https://tools.ietf.org/html/rfc6749#section-3.3) or an attribute value in a [SAML 2.0 Assertion](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html).
    ENDUSER_SCOPE = "enduser.scope",
    -- Current "managed" thread ID (as opposed to OS thread ID).
    THREAD_ID = "thread.id",
    -- Current thread name.
    THREAD_NAME = "thread.name",
    -- The method or function name, or equivalent (usually rightmost part of the code unit's name).
    CODE_FUNCTION = "code.function",
    -- The "namespace" within which `code.function` is defined. Usually the qualified class or module name, such that `code.namespace` + some separator + `code.function` form a unique identifier for the code unit.
    CODE_NAMESPACE = "code.namespace",
    -- The source code file name that identifies the code unit as uniquely as possible (preferably an absolute file path).
    CODE_FILEPATH = "code.filepath",
    -- The line number in `code.filepath` best representing the operation. It SHOULD point within the code unit named in `code.function`.
    CODE_LINENO = "code.lineno",
    -- The column number in `code.filepath` best representing the operation. It SHOULD point within the code unit named in `code.function`.
    CODE_COLUMN = "code.column"
}
return _M