# TODO:
#	iterate through all files
#	append similar tests
#	count SDs, AVGs
# 	format data for tikz
def remove_header_rows(file_path):
    # Read the content of the text file
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Remove additional text lines and repeated column headers
    cleaned_lines = []
    skip_patterns = ['Running for', 'Power measurements', '  Time']
    for line in lines:
        if not any(line.startswith(pattern) for pattern in skip_patterns):
            cleaned_lines.append(line)

    # Write the cleaned content back to the file
    with open(file_path, 'w') as file:
        file.writelines(cleaned_lines)

# Specify the path to your text file
file_path = 'outputs/populate_secondnf_powerstat_202312121439.txt'

# Call the function to remove additional text lines and repeated column headers
remove_header_rows(file_path)
