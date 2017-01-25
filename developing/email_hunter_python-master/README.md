# email_hunter_python
### An Email Hunter API client written in Python

## Installation
Requirements:

* Python 3 (because it's 2015)


To install:
```
pip install email-hunter-python
```

To update:
```
pip install --upgrade email-hunter-python
```

## Usage

email_hunter_python supports the three main methods of the [Email Hunter](https://emailhunter.co/api/docs) API:
`search`, `generate`, and `exist`. There are two ways to use email_hunter_python:

* As a Python library
* As a command line (CLI) tool.

#### To use the email_hunter_python Python library:

Import the client and instantiate it:
```python
from email_hunter import EmailHunterClient
```
```
client = EmailHunterClient('my_api_key')
```

You can search:
```python
client.search('google.com')
```

A max of 100 results are returned, so use offset to paginate:
```python
client.search('google.com', offset=1)
```

You can also change type (personal or generic):
```python
client.search('google.com', type='personal')
```

You can generate:
```python
client.generate('google.com', 'Sergey', 'Brin')
```

And you can check if an email exists:
```python
client.exist('sergey@google.com')
```

#### To use email_hunter_python as a CLI tool:

```
email_hunter [command name] [api_key] [other args]
```

The command name is `search`, `generate` or `exist`, the api_key is the API key associated with your Email Hunter
account

The other arguments depend on the command you are using:
```
--domain       Required for search and generate commands
--offset       Optional, used with search command.
--type         Optional, used with search command
--first_name   Required for generate command
--last_name    Required for generate command
--email        Required for exist command
--file         Path to a CSV to be used with the specified command.
               CSV must have a column for each argument used.
```

The file argument is useful when you want to make several requests of the same type. For example if you wanted to find
the email addresses for several people at an organization you would do the following:
```
email_hunter generate [api_key] --file people.csv > emails.csv
```
Where `people.csv` looks like:

```
domain,first_name,last_name
google.com,larry,page
google.com,sergey,brin
facebook.com,mark,zuckerberg
```

The output will also be in a CSV format.

## License
Copyright © 2015 Alan Vezina

Released under The MIT License (MIT), see the LICENSE file for details