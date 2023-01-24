with open("SSLSCANFULL.txt", mode="r") as bigfile:
    smallfile_prefix = "File_"
    file_count = 0
    smallfile = open(smallfile_prefix + str(file_count), 'w')
    for line in bigfile:
        if line.startswith("Testing"):
           # smallfile.write(line)
            smallfile.close()
            file_count += 1
            smallfile = open(smallfile_prefix + str(file_count), 'w')
            smallfile.write(line)
        else:
            smallfile.write(line)
    smallfile.close()
