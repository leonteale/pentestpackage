import pypandoc

long_description = pypandoc.convert('README.md', 'rst')
f = open('README.txt','w+')
f.write(long_description)
f.close()
