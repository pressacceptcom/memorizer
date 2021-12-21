tool
class_name PressAccept_Memorizer_Store

# |======================================|
# |                                      |
# |         Press Accept: Memorizer      |
# | Page-Based Addressable Sparse Memory |
# |                                      |
# |======================================|
#
# This module is a class that creates an addressable (by byte) memory space
#
# With write_to_address you can pass anything indexable, including Strings. With
# Strings, you can specify an 'encoding' (ascii, wchar, or utf8 with utf8 as
# the default). With other indexables, the value of each indice is first
# converted to an int with int() and then filtered to a value between 0-255
# using 0xff as a bitmask.
#
# With read_form_address, if the address space doesn't exist yet, it will be
# created, so keep that in mind.
#
# |------------------|
# | Meta Information |
# |------------------|
#
# Organization Namespace : PressAccept
# Package Namespace      : Memorizer
# Class                  : Store
#
# Organization        : Press Accept
# Organization URI    : https://pressaccept.com/
# Organization Social : @pressaccept
#
# Author        : Asher Kadar Wolfstein
# Author URI    : https://wunk.me/ (Personal Blog)
# Author Social : https://incarnate.me/members/asherwolfstein/
#                 @asherwolfstein (Twitter)
#                 https://ko-fi.com/asherwolfstein
#
# Copyright : Press Accept: Typer © 2021 The Novelty Factor LLC
#                 (Press Accept, Asher Kadar Wolfstein)
# License   : Proprietary. All Rights Reserved.
#
# |-----------|
# | Changelog |
# |-----------|
#
# 1.0.0    12/20/2021    First Release
#

# *************
# | Constants |
# *************

# the default page/slot size
const INT_DEFAULT_BYTE_POOL_SIZE: int = 1024 # 1 kilobyte

# string encoding formats (write_to_address)
const STR_STRING_ENCODING_UTF8  : String = 'utf8'
const STR_STRING_ENCODING_ASCII : String = 'ascii'
const STR_STRING_ENCODING_WCHAR : String = 'wchar'

# *********************
# | Public Properties |
# *********************

# the size of a page, once set it can't be altered
var byte_pool_size : int setget _set_byte_pool_size

# **********************
# | Private Properties |
# **********************

# the dictionary, keys are the pages/slots of the memory space
var _memory_store  : Dictionary = {}


# ***************
# | Constructor |
# ***************


func _init(
		init_byte_pool_size: int = INT_DEFAULT_BYTE_POOL_SIZE) -> void:

	byte_pool_size = init_byte_pool_size


# ******************
# | Public Methods |
# ******************


# write a series of bytes (accepts a scalar too) to the space at start_address
#
# all values are run through int() and bit masked against 0xff
# returns false on success, String on failure
#
# NOTE: Specify an encoding in the third parameter (optional)
func write_to_address(
		start_address : int,
		value,               # byte (0-255), String, or (PoolByte)Array
		use: String = STR_STRING_ENCODING_UTF8):

	if not PressAccept_Typer_Typer.is_indexable(
				PressAccept_Typer_Typer.get_type(value)
			):
		value = [ value ]

	if value is String:
		match use:
			STR_STRING_ENCODING_ASCII:
				value = value.to_ascii()
			STR_STRING_ENCODING_WCHAR:
				value = value.to_wchar()
			_:
				value = value.to_utf8()

	var end_address = start_address + len(value)
	if end_address < start_address:
		return 'Error: Maximum Address Limit Exceeded'

	var start_slot : int = int(start_address / byte_pool_size)
	var end_slot   : int = int(end_address / byte_pool_size)
	start_address        = start_address % byte_pool_size
	end_address          = end_address % byte_pool_size

	if start_slot == end_slot:
		if not _memory_store.has(start_slot):
			# if I operate on _memory_store[start_slot] directly,
			#     it doesn't seem to resize - wtf?
			var byte_array: PoolByteArray = PoolByteArray()
			byte_array.resize(byte_pool_size)
			for address in range(0, byte_pool_size):
				byte_array[address] = 0
			_memory_store[start_slot] = byte_array
		for address in range(start_address, end_address):
			_memory_store[start_slot][address] = \
				int(value[address - start_address]) & 0xff
	else:
		for slot in range(start_slot, end_slot + 1):
			if not _memory_store.has(slot):
				var byte_array: PoolByteArray = PoolByteArray()
				byte_array.resize(byte_pool_size)
				for address in range(0, byte_pool_size):
					byte_array[address] = 0
				_memory_store[slot] = byte_array

		var counter: int = 0
		for address in range(start_address, byte_pool_size):
			_memory_store[start_slot][address] = int(value[counter]) & 0xff
			counter += 1
		for slot in range(start_slot + 1, end_slot):
			for address in range(0, byte_pool_size):
				_memory_store[slot][address] = int(value[counter]) & 0xff
				counter += 1
		for address in range(0, end_address):
			_memory_store[end_slot][address] = int(value[counter]) & 0xff
			counter += 1

	return false


# read a series of bytes form the memory space
#
# returns PoolByteArray on success, String on failure
#
# NOTE: reading at a particular address will CREATE the necessary slots/pages
func read_from_address(
		start_address : int,
		length        : int): # -> 

	var end_address = start_address + length
	if end_address < start_address:
		return 'Error: Maximum Address Limit Exceeded'

	var start_slot : int = int(start_address / byte_pool_size)
	var end_slot   : int = int(end_address / byte_pool_size)
	start_address        = start_address % byte_pool_size
	end_address          = end_address % byte_pool_size

	if start_slot == end_slot:
		if not _memory_store.has(start_slot):
			# if I operate on _memory_store[start_slot] directly,
			#     it doesn't seem to resize - wtf?
			var byte_array: PoolByteArray = PoolByteArray()
			byte_array.resize(byte_pool_size)
			for address in range(0, byte_pool_size):
				byte_array[address] = 0
			_memory_store[start_slot] = byte_array
		return _memory_store[start_slot].subarray(start_address, end_address)
	else:
		var return_bytes: PoolByteArray = PoolByteArray()
		return_bytes.resize(length)

		for slot in range(start_slot, end_slot + 1):
			if not _memory_store.has(slot):
				var byte_array: PoolByteArray = PoolByteArray()
				byte_array.resize(byte_pool_size)
				for address in range(0, byte_pool_size):
					byte_array[address] = 0
				_memory_store[slot] = byte_array

		var counter: int = 0
		for address in range(start_address, byte_pool_size):
			return_bytes[counter] = _memory_store[start_slot][address]
			counter += 1
		for slot in range(start_slot + 1, end_slot):
			for address in range(0, byte_pool_size):
				return_bytes[counter] = _memory_store[slot][address]
				counter += 1
		for address in range(0, end_address):
			return_bytes[counter] = _memory_store[end_slot][address]
			counter += 1

		return return_bytes

