import xlrd
import pickle
import random

def get_raw_data():
	book = xlrd.open_workbook("data.xlsx")
	sheet = book.sheet_by_index(2)
	
	langs = []
	params = []
	
	for x in xrange(3, 254):
		langs.append(sheet.row(x)[0].value)
		current_row = sheet.row(x)[1:]
		row = []
		for element in current_row:
			row.append(element.value)
		del row[-1]
		params.append(row)
		
	pickle.dump(params, open("params.p", "wb"))
	pickle.dump(langs, open("langs.p", "wb"))
	
# randomized subsets, at least 60 known parameters in total
def data_selection():
	params = pickle.load(open("params.p", "rb"))
	langs = pickle.load(open("langs.p", "rb"))
	
	subset_enough_params = []
	selected_data = []
	
	for lang in params:
		if lang.count(0.0) + lang.count(1.0) >= 60:
			subset_enough_params.append(lang)
	
	selected_langs = random.sample(xrange(len(subset_enough_params)), 15)
	for l in selected_langs:
		selected_data.append(subset_enough_params[l])
			
	return selected_data
			
def write_input_data_to_file(selected_data, x):
	filename = "input{0}.txt".format(x)
	with open(filename, "w") as f:
		for vector in selected_data:
			str_vector = [str(param) for param in vector]
			f.write(" ".join(str_vector))
			f.write("\n")

for x in xrange(20):
	write_input_data_to_file(data_selection(), x)
		