#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class TracesData:
	func _init():
		var service
		
		var __resource_spans_default: Array[ResourceSpans] = []
		__resource_spans = PBField.new("resource_spans", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __resource_spans_default)
		service = PBServiceField.new()
		service.field = __resource_spans
		service.func_ref = Callable(self, "add_resource_spans")
		data[__resource_spans.tag] = service
		
	var data = {}
	
	var __resource_spans: PBField
	func get_resource_spans() -> Array[ResourceSpans]:
		return __resource_spans.value
	func clear_resource_spans() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__resource_spans.value = []
	func add_resource_spans() -> ResourceSpans:
		var element = ResourceSpans.new()
		__resource_spans.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ResourceSpans:
	func _init():
		var service
		
		__resource = PBField.new("resource", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __resource
		service.func_ref = Callable(self, "new_resource")
		data[__resource.tag] = service
		
		var __instrumentation_library_spans_default: Array[InstrumentationLibrarySpans] = []
		__instrumentation_library_spans = PBField.new("instrumentation_library_spans", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __instrumentation_library_spans_default)
		service = PBServiceField.new()
		service.field = __instrumentation_library_spans
		service.func_ref = Callable(self, "add_instrumentation_library_spans")
		data[__instrumentation_library_spans.tag] = service
		
		__schema_url = PBField.new("schema_url", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __schema_url
		data[__schema_url.tag] = service
		
	var data = {}
	
	var __resource: PBField
	func get_resource() -> TraceResource:
		return __resource.value
	func clear_resource() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__resource.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_resource() -> TraceResource:
		__resource.value = TraceResource.new()
		return __resource.value
	
	var __instrumentation_library_spans: PBField
	func get_instrumentation_library_spans() -> Array[InstrumentationLibrarySpans]:
		return __instrumentation_library_spans.value
	func clear_instrumentation_library_spans() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__instrumentation_library_spans.value = []
	func add_instrumentation_library_spans() -> InstrumentationLibrarySpans:
		var element = InstrumentationLibrarySpans.new()
		__instrumentation_library_spans.value.append(element)
		return element
	
	var __schema_url: PBField
	func get_schema_url() -> String:
		return __schema_url.value
	func clear_schema_url() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__schema_url.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_schema_url(value : String) -> void:
		__schema_url.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InstrumentationLibrarySpans:
	func _init():
		var service
		
		__instrumentation_library = PBField.new("instrumentation_library", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __instrumentation_library
		service.func_ref = Callable(self, "new_instrumentation_library")
		data[__instrumentation_library.tag] = service
		
		var __spans_default: Array[Span] = []
		__spans = PBField.new("spans", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __spans_default)
		service = PBServiceField.new()
		service.field = __spans
		service.func_ref = Callable(self, "add_spans")
		data[__spans.tag] = service
		
		__schema_url = PBField.new("schema_url", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __schema_url
		data[__schema_url.tag] = service
		
	var data = {}
	
	var __instrumentation_library: PBField
	func get_instrumentation_library() -> InstrumentationLibrary:
		return __instrumentation_library.value
	func clear_instrumentation_library() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__instrumentation_library.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_instrumentation_library() -> InstrumentationLibrary:
		__instrumentation_library.value = InstrumentationLibrary.new()
		return __instrumentation_library.value
	
	var __spans: PBField
	func get_spans() -> Array[Span]:
		return __spans.value
	func clear_spans() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__spans.value = []
	func add_spans() -> Span:
		var element = Span.new()
		__spans.value.append(element)
		return element
	
	var __schema_url: PBField
	func get_schema_url() -> String:
		return __schema_url.value
	func clear_schema_url() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__schema_url.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_schema_url(value : String) -> void:
		__schema_url.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Span:
	func _init():
		var service
		
		__trace_id = PBField.new("trace_id", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __trace_id
		data[__trace_id.tag] = service
		
		__span_id = PBField.new("span_id", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __span_id
		data[__span_id.tag] = service
		
		__trace_state = PBField.new("trace_state", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __trace_state
		data[__trace_state.tag] = service
		
		__parent_span_id = PBField.new("parent_span_id", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __parent_span_id
		data[__parent_span_id.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__kind = PBField.new("kind", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __kind
		data[__kind.tag] = service
		
		__start_time_unix_nano = PBField.new("start_time_unix_nano", PB_DATA_TYPE.FIXED64, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64])
		service = PBServiceField.new()
		service.field = __start_time_unix_nano
		data[__start_time_unix_nano.tag] = service
		
		__end_time_unix_nano = PBField.new("end_time_unix_nano", PB_DATA_TYPE.FIXED64, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64])
		service = PBServiceField.new()
		service.field = __end_time_unix_nano
		data[__end_time_unix_nano.tag] = service
		
		var __attributes_default: Array[KeyValue] = []
		__attributes = PBField.new("attributes", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 9, true, __attributes_default)
		service = PBServiceField.new()
		service.field = __attributes
		service.func_ref = Callable(self, "add_attributes")
		data[__attributes.tag] = service
		
		__dropped_attributes_count = PBField.new("dropped_attributes_count", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __dropped_attributes_count
		data[__dropped_attributes_count.tag] = service
		
		var __events_default: Array[Span.Event] = []
		__events = PBField.new("events", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 11, true, __events_default)
		service = PBServiceField.new()
		service.field = __events
		service.func_ref = Callable(self, "add_events")
		data[__events.tag] = service
		
		__dropped_events_count = PBField.new("dropped_events_count", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __dropped_events_count
		data[__dropped_events_count.tag] = service
		
		var __links_default: Array[Span.Link] = []
		__links = PBField.new("links", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 13, true, __links_default)
		service = PBServiceField.new()
		service.field = __links
		service.func_ref = Callable(self, "add_links")
		data[__links.tag] = service
		
		__dropped_links_count = PBField.new("dropped_links_count", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __dropped_links_count
		data[__dropped_links_count.tag] = service
		
		__status = PBField.new("status", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __status
		service.func_ref = Callable(self, "new_status")
		data[__status.tag] = service
		
	var data = {}
	
	var __trace_id: PBField
	func get_trace_id() -> PackedByteArray:
		return __trace_id.value
	func clear_trace_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__trace_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_trace_id(value : PackedByteArray) -> void:
		__trace_id.value = value
	
	var __span_id: PBField
	func get_span_id() -> PackedByteArray:
		return __span_id.value
	func clear_span_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__span_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_span_id(value : PackedByteArray) -> void:
		__span_id.value = value
	
	var __trace_state: PBField
	func get_trace_state() -> String:
		return __trace_state.value
	func clear_trace_state() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__trace_state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_trace_state(value : String) -> void:
		__trace_state.value = value
	
	var __parent_span_id: PBField
	func get_parent_span_id() -> PackedByteArray:
		return __parent_span_id.value
	func clear_parent_span_id() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__parent_span_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_parent_span_id(value : PackedByteArray) -> void:
		__parent_span_id.value = value
	
	var __name: PBField
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __kind: PBField
	func get_kind():
		return __kind.value
	func clear_kind() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__kind.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_kind(value) -> void:
		__kind.value = value
	
	var __start_time_unix_nano: PBField
	func get_start_time_unix_nano() -> int:
		return __start_time_unix_nano.value
	func clear_start_time_unix_nano() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__start_time_unix_nano.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64]
	func set_start_time_unix_nano(value : int) -> void:
		__start_time_unix_nano.value = value
	
	var __end_time_unix_nano: PBField
	func get_end_time_unix_nano() -> int:
		return __end_time_unix_nano.value
	func clear_end_time_unix_nano() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__end_time_unix_nano.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64]
	func set_end_time_unix_nano(value : int) -> void:
		__end_time_unix_nano.value = value
	
	var __attributes: PBField
	func get_attributes() -> Array[KeyValue]:
		return __attributes.value
	func clear_attributes() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__attributes.value = []
	func add_attributes() -> KeyValue:
		var element = KeyValue.new()
		__attributes.value.append(element)
		return element
	
	var __dropped_attributes_count: PBField
	func get_dropped_attributes_count() -> int:
		return __dropped_attributes_count.value
	func clear_dropped_attributes_count() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__dropped_attributes_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_dropped_attributes_count(value : int) -> void:
		__dropped_attributes_count.value = value
	
	var __events: PBField
	func get_events() -> Array[Span.Event]:
		return __events.value
	func clear_events() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__events.value = []
	func add_events() -> Span.Event:
		var element = Span.Event.new()
		__events.value.append(element)
		return element
	
	var __dropped_events_count: PBField
	func get_dropped_events_count() -> int:
		return __dropped_events_count.value
	func clear_dropped_events_count() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__dropped_events_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_dropped_events_count(value : int) -> void:
		__dropped_events_count.value = value
	
	var __links: PBField
	func get_links() -> Array[Span.Link]:
		return __links.value
	func clear_links() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__links.value = []
	func add_links() -> Span.Link:
		var element = Span.Link.new()
		__links.value.append(element)
		return element
	
	var __dropped_links_count: PBField
	func get_dropped_links_count() -> int:
		return __dropped_links_count.value
	func clear_dropped_links_count() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__dropped_links_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_dropped_links_count(value : int) -> void:
		__dropped_links_count.value = value
	
	var __status: PBField
	func get_status() -> Status:
		return __status.value
	func clear_status() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__status.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_status() -> Status:
		__status.value = Status.new()
		return __status.value
	
	enum SpanKind {
		SPAN_KIND_UNSPECIFIED = 0,
		SPAN_KIND_INTERNAL = 1,
		SPAN_KIND_SERVER = 2,
		SPAN_KIND_CLIENT = 3,
		SPAN_KIND_PRODUCER = 4,
		SPAN_KIND_CONSUMER = 5
	}
	
	class Event:
		func _init():
			var service
			
			__time_unix_nano = PBField.new("time_unix_nano", PB_DATA_TYPE.FIXED64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64])
			service = PBServiceField.new()
			service.field = __time_unix_nano
			data[__time_unix_nano.tag] = service
			
			__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			service = PBServiceField.new()
			service.field = __name
			data[__name.tag] = service
			
			var __attributes_default: Array[KeyValue] = []
			__attributes = PBField.new("attributes", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 3, true, __attributes_default)
			service = PBServiceField.new()
			service.field = __attributes
			service.func_ref = Callable(self, "add_attributes")
			data[__attributes.tag] = service
			
			__dropped_attributes_count = PBField.new("dropped_attributes_count", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
			service = PBServiceField.new()
			service.field = __dropped_attributes_count
			data[__dropped_attributes_count.tag] = service
			
		var data = {}
		
		var __time_unix_nano: PBField
		func get_time_unix_nano() -> int:
			return __time_unix_nano.value
		func clear_time_unix_nano() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__time_unix_nano.value = DEFAULT_VALUES_3[PB_DATA_TYPE.FIXED64]
		func set_time_unix_nano(value : int) -> void:
			__time_unix_nano.value = value
		
		var __name: PBField
		func get_name() -> String:
			return __name.value
		func clear_name() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_name(value : String) -> void:
			__name.value = value
		
		var __attributes: PBField
		func get_attributes() -> Array[KeyValue]:
			return __attributes.value
		func clear_attributes() -> void:
			data[3].state = PB_SERVICE_STATE.UNFILLED
			__attributes.value = []
		func add_attributes() -> KeyValue:
			var element = KeyValue.new()
			__attributes.value.append(element)
			return element
		
		var __dropped_attributes_count: PBField
		func get_dropped_attributes_count() -> int:
			return __dropped_attributes_count.value
		func clear_dropped_attributes_count() -> void:
			data[4].state = PB_SERVICE_STATE.UNFILLED
			__dropped_attributes_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
		func set_dropped_attributes_count(value : int) -> void:
			__dropped_attributes_count.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	class Link:
		func _init():
			var service
			
			__trace_id = PBField.new("trace_id", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
			service = PBServiceField.new()
			service.field = __trace_id
			data[__trace_id.tag] = service
			
			__span_id = PBField.new("span_id", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
			service = PBServiceField.new()
			service.field = __span_id
			data[__span_id.tag] = service
			
			__trace_state = PBField.new("trace_state", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
			service = PBServiceField.new()
			service.field = __trace_state
			data[__trace_state.tag] = service
			
			var __attributes_default: Array[KeyValue] = []
			__attributes = PBField.new("attributes", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 4, true, __attributes_default)
			service = PBServiceField.new()
			service.field = __attributes
			service.func_ref = Callable(self, "add_attributes")
			data[__attributes.tag] = service
			
			__dropped_attributes_count = PBField.new("dropped_attributes_count", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
			service = PBServiceField.new()
			service.field = __dropped_attributes_count
			data[__dropped_attributes_count.tag] = service
			
		var data = {}
		
		var __trace_id: PBField
		func get_trace_id() -> PackedByteArray:
			return __trace_id.value
		func clear_trace_id() -> void:
			data[1].state = PB_SERVICE_STATE.UNFILLED
			__trace_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		func set_trace_id(value : PackedByteArray) -> void:
			__trace_id.value = value
		
		var __span_id: PBField
		func get_span_id() -> PackedByteArray:
			return __span_id.value
		func clear_span_id() -> void:
			data[2].state = PB_SERVICE_STATE.UNFILLED
			__span_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		func set_span_id(value : PackedByteArray) -> void:
			__span_id.value = value
		
		var __trace_state: PBField
		func get_trace_state() -> String:
			return __trace_state.value
		func clear_trace_state() -> void:
			data[3].state = PB_SERVICE_STATE.UNFILLED
			__trace_state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		func set_trace_state(value : String) -> void:
			__trace_state.value = value
		
		var __attributes: PBField
		func get_attributes() -> Array[KeyValue]:
			return __attributes.value
		func clear_attributes() -> void:
			data[4].state = PB_SERVICE_STATE.UNFILLED
			__attributes.value = []
		func add_attributes() -> KeyValue:
			var element = KeyValue.new()
			__attributes.value.append(element)
			return element
		
		var __dropped_attributes_count: PBField
		func get_dropped_attributes_count() -> int:
			return __dropped_attributes_count.value
		func clear_dropped_attributes_count() -> void:
			data[5].state = PB_SERVICE_STATE.UNFILLED
			__dropped_attributes_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
		func set_dropped_attributes_count(value : int) -> void:
			__dropped_attributes_count.value = value
		
		func _to_string() -> String:
			return PBPacker.message_to_string(data)
			
		func to_bytes() -> PackedByteArray:
			return PBPacker.pack_message(data)
			
		func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
			var cur_limit = bytes.size()
			if limit != -1:
				cur_limit = limit
			var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
			if result == cur_limit:
				if PBPacker.check_required(data):
					if limit == -1:
						return PB_ERR.NO_ERRORS
				else:
					return PB_ERR.REQUIRED_FIELDS
			elif limit == -1 && result > 0:
				return PB_ERR.PARSE_INCOMPLETE
			return result
		
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Status:
	func _init():
		var service
		
		__deprecated_code = PBField.new("deprecated_code", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __deprecated_code
		data[__deprecated_code.tag] = service
		
		__developer_message = PBField.new("developer_message", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __developer_message
		data[__developer_message.tag] = service
		
		__code = PBField.new("code", PB_DATA_TYPE.ENUM, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM])
		service = PBServiceField.new()
		service.field = __code
		data[__code.tag] = service
		
	var data = {}
	
	var __deprecated_code: PBField
	func get_deprecated_code():
		return __deprecated_code.value
	func clear_deprecated_code() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__deprecated_code.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_deprecated_code(value) -> void:
		__deprecated_code.value = value
	
	var __developer_message: PBField
	func get_developer_message() -> String:
		return __developer_message.value
	func clear_developer_message() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__developer_message.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_developer_message(value : String) -> void:
		__developer_message.value = value
	
	var __code: PBField
	func get_code():
		return __code.value
	func clear_code() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__code.value = DEFAULT_VALUES_3[PB_DATA_TYPE.ENUM]
	func set_code(value) -> void:
		__code.value = value
	
	enum DeprecatedStatusCode {
		DEPRECATED_STATUS_CODE_OK = 0,
		DEPRECATED_STATUS_CODE_CANCELLED = 1,
		DEPRECATED_STATUS_CODE_UNKNOWN_ERROR = 2,
		DEPRECATED_STATUS_CODE_INVALID_ARGUMENT = 3,
		DEPRECATED_STATUS_CODE_DEADLINE_EXCEEDED = 4,
		DEPRECATED_STATUS_CODE_NOT_FOUND = 5,
		DEPRECATED_STATUS_CODE_ALREADY_EXISTS = 6,
		DEPRECATED_STATUS_CODE_PERMISSION_DENIED = 7,
		DEPRECATED_STATUS_CODE_RESOURCE_EXHAUSTED = 8,
		DEPRECATED_STATUS_CODE_FAILED_PRECONDITION = 9,
		DEPRECATED_STATUS_CODE_ABORTED = 10,
		DEPRECATED_STATUS_CODE_OUT_OF_RANGE = 11,
		DEPRECATED_STATUS_CODE_UNIMPLEMENTED = 12,
		DEPRECATED_STATUS_CODE_INTERNAL_ERROR = 13,
		DEPRECATED_STATUS_CODE_UNAVAILABLE = 14,
		DEPRECATED_STATUS_CODE_DATA_LOSS = 15,
		DEPRECATED_STATUS_CODE_UNAUTHENTICATED = 16
	}
	
	enum StatusCode {
		STATUS_CODE_UNSET = 0,
		STATUS_CODE_OK = 1,
		STATUS_CODE_ERROR = 2
	}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AnyValue:
	func _init():
		var service
		
		__string_value = PBField.new("string_value", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __string_value
		data[__string_value.tag] = service
		
		__bool_value = PBField.new("bool_value", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __bool_value
		data[__bool_value.tag] = service
		
		__int_value = PBField.new("int_value", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = __int_value
		data[__int_value.tag] = service
		
		__double_value = PBField.new("double_value", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = __double_value
		data[__double_value.tag] = service
		
		__array_value = PBField.new("array_value", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __array_value
		service.func_ref = Callable(self, "new_array_value")
		data[__array_value.tag] = service
		
		__kvlist_value = PBField.new("kvlist_value", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __kvlist_value
		service.func_ref = Callable(self, "new_kvlist_value")
		data[__kvlist_value.tag] = service
		
		__bytes_value = PBField.new("bytes_value", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = __bytes_value
		data[__bytes_value.tag] = service
		
	var data = {}
	
	var __string_value: PBField
	func has_string_value() -> bool:
		return data[1].state == PB_SERVICE_STATE.FILLED
	func get_string_value() -> String:
		return __string_value.value
	func clear_string_value() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__string_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_string_value(value : String) -> void:
		data[1].state = PB_SERVICE_STATE.FILLED
		__bool_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__int_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__double_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__array_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__kvlist_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__bytes_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__string_value.value = value
	
	var __bool_value: PBField
	func has_bool_value() -> bool:
		return data[2].state == PB_SERVICE_STATE.FILLED
	func get_bool_value() -> bool:
		return __bool_value.value
	func clear_bool_value() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__bool_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_bool_value(value : bool) -> void:
		__string_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		data[2].state = PB_SERVICE_STATE.FILLED
		__int_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__double_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__array_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__kvlist_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__bytes_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__bool_value.value = value
	
	var __int_value: PBField
	func has_int_value() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func get_int_value() -> int:
		return __int_value.value
	func clear_int_value() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__int_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_int_value(value : int) -> void:
		__string_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__bool_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		data[3].state = PB_SERVICE_STATE.FILLED
		__double_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__array_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__kvlist_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__bytes_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__int_value.value = value
	
	var __double_value: PBField
	func has_double_value() -> bool:
		return data[4].state == PB_SERVICE_STATE.FILLED
	func get_double_value() -> float:
		return __double_value.value
	func clear_double_value() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__double_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_double_value(value : float) -> void:
		__string_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__bool_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__int_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		data[4].state = PB_SERVICE_STATE.FILLED
		__array_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__kvlist_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__bytes_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__double_value.value = value
	
	var __array_value: PBField
	func has_array_value() -> bool:
		return data[5].state == PB_SERVICE_STATE.FILLED
	func get_array_value() -> ArrayValue:
		return __array_value.value
	func clear_array_value() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__array_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_array_value() -> ArrayValue:
		__string_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__bool_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__int_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__double_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		data[5].state = PB_SERVICE_STATE.FILLED
		__kvlist_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__bytes_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__array_value.value = ArrayValue.new()
		return __array_value.value
	
	var __kvlist_value: PBField
	func has_kvlist_value() -> bool:
		return data[6].state == PB_SERVICE_STATE.FILLED
	func get_kvlist_value() -> KeyValueList:
		return __kvlist_value.value
	func clear_kvlist_value() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__kvlist_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_kvlist_value() -> KeyValueList:
		__string_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__bool_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__int_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__double_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__array_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		data[6].state = PB_SERVICE_STATE.FILLED
		__bytes_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__kvlist_value.value = KeyValueList.new()
		return __kvlist_value.value
	
	var __bytes_value: PBField
	func has_bytes_value() -> bool:
		return data[7].state == PB_SERVICE_STATE.FILLED
	func get_bytes_value() -> PackedByteArray:
		return __bytes_value.value
	func clear_bytes_value() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__bytes_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_bytes_value(value : PackedByteArray) -> void:
		__string_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__bool_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__int_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__double_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__array_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__kvlist_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		data[7].state = PB_SERVICE_STATE.FILLED
		__bytes_value.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ArrayValue:
	func _init():
		var service
		
		var __values_default: Array[AnyValue] = []
		__values = PBField.new("values", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __values_default)
		service = PBServiceField.new()
		service.field = __values
		service.func_ref = Callable(self, "add_values")
		data[__values.tag] = service
		
	var data = {}
	
	var __values: PBField
	func get_values() -> Array[AnyValue]:
		return __values.value
	func clear_values() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__values.value = []
	func add_values() -> AnyValue:
		var element = AnyValue.new()
		__values.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class KeyValueList:
	func _init():
		var service
		
		var __values_default: Array[KeyValue] = []
		__values = PBField.new("values", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __values_default)
		service = PBServiceField.new()
		service.field = __values
		service.func_ref = Callable(self, "add_values")
		data[__values.tag] = service
		
	var data = {}
	
	var __values: PBField
	func get_values() -> Array[KeyValue]:
		return __values.value
	func clear_values() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__values.value = []
	func add_values() -> KeyValue:
		var element = KeyValue.new()
		__values.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class KeyValue:
	func _init():
		var service
		
		__key = PBField.new("key", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __key
		data[__key.tag] = service
		
		__value = PBField.new("value", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __value
		service.func_ref = Callable(self, "new_value")
		data[__value.tag] = service
		
	var data = {}
	
	var __key: PBField
	func get_key() -> String:
		return __key.value
	func clear_key() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__key.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_key(value : String) -> void:
		__key.value = value
	
	var __value: PBField
	func get_value() -> AnyValue:
		return __value.value
	func clear_value() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_value() -> AnyValue:
		__value.value = AnyValue.new()
		return __value.value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InstrumentationLibrary:
	func _init():
		var service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__version = PBField.new("version", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __version
		data[__version.tag] = service
		
	var data = {}
	
	var __name: PBField
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __version: PBField
	func get_version() -> String:
		return __version.value
	func clear_version() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_version(value : String) -> void:
		__version.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class TraceResource:
	func _init():
		var service
		
		var __attributes_default: Array[KeyValue] = []
		__attributes = PBField.new("attributes", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 1, true, __attributes_default)
		service = PBServiceField.new()
		service.field = __attributes
		service.func_ref = Callable(self, "add_attributes")
		data[__attributes.tag] = service
		
		__dropped_attributes_count = PBField.new("dropped_attributes_count", PB_DATA_TYPE.UINT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32])
		service = PBServiceField.new()
		service.field = __dropped_attributes_count
		data[__dropped_attributes_count.tag] = service
		
	var data = {}
	
	var __attributes: PBField
	func get_attributes() -> Array[KeyValue]:
		return __attributes.value
	func clear_attributes() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__attributes.value = []
	func add_attributes() -> KeyValue:
		var element = KeyValue.new()
		__attributes.value.append(element)
		return element
	
	var __dropped_attributes_count: PBField
	func get_dropped_attributes_count() -> int:
		return __dropped_attributes_count.value
	func clear_dropped_attributes_count() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__dropped_attributes_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT32]
	func set_dropped_attributes_count(value : int) -> void:
		__dropped_attributes_count.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
