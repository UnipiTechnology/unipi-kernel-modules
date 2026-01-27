/*
 *
 * Copyright (c) 2021  Faster CZ, ondra@faster.cz
 *
 * SPDX-License-Identifier: LGPL-2.1+
 *
 */

#ifndef UNIPI_EPROM_H_
#define UNIPI_EPROM_H_

#include "uniee.h"
#include "uniee_values.h"

#ifndef min
#define min(a,b) ((a)<(b)?(a):(b))
#endif

static inline void slotstr(uint8_t* slot, int size, char* dest)
{
	int i;
	char ch;
	for (i=0; i<size; i++) {
		dest[i] = ch = slot[i];
		if (ch == 0xff || ch == '\0') {
			dest[i] = '\0';
			break;
		}
	}
}


/*
	Find property in memory block from Unipi Eprom
	returns:
			- pointer to data and length in len
			- NULL if property not found or any error in structure
*/
#define specdata_count 12
#define specdata_size  (2*UNIEE_BANK_SIZE)

static inline uint8_t* unipi_eeprom_enum_properties(uint8_t *eprom, uniee_descriptor_area* descriptor, int(*callback)(int, int, uint8_t*))
{
	int cur_type, i, len;
	int dataindex = 0;

	for (i=0; i < specdata_count; i++) {
		cur_type = descriptor->board_info.specdata_headers_table[i].field_type |
                   (((int)(descriptor->board_info.specdata_headers_table[i].field_len & (~0x3f)))<<2);
		len = descriptor->board_info.specdata_headers_table[i].field_len & (0x3f);
		if ((dataindex + len) >= specdata_size)
			return NULL;
		if (callback(cur_type, len, eprom + dataindex) != 0) {
			return eprom + dataindex;
		}
		dataindex += len;
	}
	return NULL;
}

static inline uint8_t* unipi_eeprom_find_property(uint8_t *eprom, uniee_descriptor_area* descriptor, int property_type, int* len)
{
	int cur_type, i;
	int dataindex = 0;

	for (i=0; i < specdata_count; i++) {
		cur_type = descriptor->board_info.specdata_headers_table[i].field_type |
                   (((int)(descriptor->board_info.specdata_headers_table[i].field_len & (~0x3f)))<<2);
		*len = descriptor->board_info.specdata_headers_table[i].field_len & (0x3f);
		if ((dataindex + *len) >= specdata_size)
			return NULL;
		if (cur_type == property_type) {
			return eprom + dataindex;
		}
		dataindex += *len;
	}
	return NULL;
}

/*
	Find unsigned integer property in memory block from Unipi Eprom
	returns:
			- original length of property data (0-8) and uint value
			- negative number if error
*/
static inline int unipi_eeprom_get_uint_property(uint8_t *eprom, uniee_descriptor_area* descriptor, int property_type, unsigned long *value)
{
	int len;
	uint8_t* ptr = unipi_eeprom_find_property(eprom, descriptor, property_type, &len);
	if (ptr == NULL) return -1;
	if (len > sizeof(*value)) return -1;
	*value = 0;
	memcpy(value, ptr, len);
	return len;
}

/*
	Find bytes property in memory block from Unipi Eprom
	returns:
			- original length of property data
			- negative number if error
*/
static inline int unipi_eeprom_get_bytes_property(uint8_t *eprom, uniee_descriptor_area* descriptor, int property_type, uint8_t* bytes, int maxlen)
{
	int len;
	uint8_t *ptr = unipi_eeprom_find_property(eprom, descriptor, property_type, &len);

	if (len <= 0) return len;
	memcpy(bytes, ptr, min(len,maxlen));
	return len;
}

/*
	Find string property in memory block from Unipi Eprom
	returns:
			- original length of property data and null terminated str
			- negative number if error
*/
static inline int unipi_eeprom_get_str_property(uint8_t *eprom, uniee_descriptor_area* descriptor, int property_type, char* str, int maxlen)
{
	int len;
	uint8_t *ptr = unipi_eeprom_find_property(eprom, descriptor, property_type, &len);

	if (len < 0) return len;
	if (len == 0) {
		str[0] = '\0';
	} else {
		slotstr(ptr, min(len,maxlen-1), str);
		str[min(len,maxlen-1)] = '\0';
	}
	return len;
}


static inline uint32_t unipi_eeprom_get_serial(uniee_descriptor_area* descriptor)
{
	uint32_t serial = descriptor->product_info.product_serial;
	if (serial == 0xffffffff) serial = 0;
	return serial;
}

static inline uint32_t unipi_eeprom_get_sku(uniee_descriptor_area* descriptor)
{
	uint32_t sku = descriptor->product_info.sku;
	if (sku == 0xffffffff) sku = 0;
	return sku;
}

static inline void unipi_eeprom_get_model(uniee_descriptor_area* descriptor, char* str, int maxlen)
{
	int len = min((int) sizeof(descriptor->product_info.model_str), maxlen-1);
	slotstr(descriptor->product_info.model_str, len, str);
	str[len]= '\0';
}


#endif /* UNIPI_EPROM_H_*/
