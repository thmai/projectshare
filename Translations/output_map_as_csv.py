import pickle
import csv

def load_map_from_pickle():
	map = file_pickle = open('map.donottouch', 'rb')
	MAP_BLAH_TO_ENGLISH = pickle.load(file_pickle)
	return MAP_BLAH_TO_ENGLISH

def output_map_as_csv_manually(map, file_name):
	writer = open(file_name, 'w')
	for key, value in map.items():
		s = key + ',' + value + '\n'
		print(s)
		writer.write(s)

def output_map_as_csv(map, file_name):
	writer = csv.writer(open(file_name, 'w'))
	for key, value in map.items():
   		writer.writerow([key, value])

if __name__ == '__main__':
	map = load_map_from_pickle()
	output_map_as_csv(map, 'blah_to_english.csv')