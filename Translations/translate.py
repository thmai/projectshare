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

f = open('input.txt', 'r')
f_str = f.read()
f_list = f_str.split('\n')

def main():

  # Build a service object for interacting with the API. Visit
  # the Google APIs Console <http://code.google.com/apis/console>
  # to get an API key for your own application.
	service = build('translate', 'v2',
            developerKey='AIzaSyBERnUYy4_-ZTTZkv_9ReT2mGlyHG0-9qY')

# q = f_list
	for text_original in f_list:
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
						print(translations[0]['translatedText'])
			except googleapiclient.errors.HttpError as e:
				print(e)
		else:
			print('More than 1 language possible')



	# print(service.translations().list(
	#       source='en',
	#       target='fr',
	#       q=['flower', 'car']
	#     ).execute())

if __name__ == '__main__':
  main()