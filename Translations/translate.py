# -*- coding: utf-8 -*-
#
# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import googleapiclient
from googleapiclient.discovery import build
import pickle
import argparse
import re

MAP_BLAH_TO_ENGLISH = None

try:
	file_pickle = open('map.donottouch', 'rb')
	MAP_BLAH_TO_ENGLISH = pickle.load(file_pickle)
except FileNotFoundError as e:
	MAP_BLAH_TO_ENGLISH = {}
	pickle.dump(MAP_BLAH_TO_ENGLISH, open("map.donottouch", "wb" ))

def open_file_and_split_into_list(path):
	f = open(path, 'r')
	f_str = f.read()
	f_list = f_str.split('\n')
	return f_list

def store_in_map_and_print(map, key, value):
	map[key] = value
	print(value)

def is_text_combination_of_some_special_characters(text):
	text_without_spaces = text.strip()
	p = re.compile('[(\?)(\\)(／)(？)]*')
	if not p.match(text_without_spaces):
		return False
	matched_object = p.match(text_without_spaces)
	if matched_object.end() != len(text_without_spaces):
		return False
	return True


def main(list_strings):

  # Build a service object for interacting with the API. Visit
  # the Google APIs Console <http://code.google.com/apis/console>
  # to get an API key for your own application.
	service = build('translate', 'v2',
            developerKey='')

# q = f_list
	for text_original in list_strings:
		if text_original in MAP_BLAH_TO_ENGLISH:
			print(MAP_BLAH_TO_ENGLISH[text_original])
		elif not text_original.strip():
			store_in_map_and_print(MAP_BLAH_TO_ENGLISH, text_original, text_original)
		elif is_text_combination_of_some_special_characters(text_original):
			store_in_map_and_print(MAP_BLAH_TO_ENGLISH, text_original, text_original)
		else:
			try:
				val = int(text_original.strip())
				store_in_map_and_print(MAP_BLAH_TO_ENGLISH, text_original, text_original)
			except ValueError:
				try:
					val = int(text_original.strip().replace(',', ''))
					store_in_map_and_print(MAP_BLAH_TO_ENGLISH, text_original, text_original)
				except ValueError:
					response_detection = service.detections().list(q = [text_original]).execute()
					response_detection_text = response_detection['detections'][0]
					if len(response_detection_text) == 1:
						# if not response_detection_text[0]['isReliable']:
						# 	print('Not Reliable')
						# else:
						try:
							if response_detection_text[0]['language'] == 'en':
								print(text_original)
							else:
								translations = service.translations().list(source=response_detection_text[0]['language'], target='en', q=[text_original]).execute()['translations']
								if len(translations) > 1:
									print('More than 1 translation possible')
								else:
									MAP_BLAH_TO_ENGLISH[text_original] = translations[0]['translatedText']
									print(translations[0]['translatedText'])
						except googleapiclient.errors.HttpError as e:
							print(e)
					else:
						print('More than 1 language possible')
	pickle.dump(MAP_BLAH_TO_ENGLISH, open("map.donottouch", "wb" ))



	# print(service.translations().list(
	#       source='en',
	#       target='fr',
	#       q=['flower', 'car']
	#     ).execute())

if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument("input", help="input file with pieces of text to be translated in different lines")
	args = parser.parse_args()
	f_list = open_file_and_split_into_list(args.input)
	main(f_list)