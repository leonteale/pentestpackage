# Copyright 2015 Alan Vezina. All rights reserved.
import argparse
from csv import DictReader
import json
import time
from functools import reduce
from email_hunter import EmailHunterClient

THROTTLE = 0.2


def reduce_sources(sources):
    def reducer(value, element):
        value.append(element['uri'])

        return value

    return ';'.join(reduce(reducer, sources, []))


def validate_search_file(reader: DictReader):
    field_names = reader.fieldnames

    if 'domain' not in field_names:
        print('domain column is required')
        return False

    return True


def validate_generate_file(reader: DictReader):
    valid = True
    field_names = reader.fieldnames

    if 'domain' not in field_names:
        print('domain column is required')

    if 'first_name' not in field_names:
        print('first_name column is required')

    if 'last_name' not in field_names:
        print('last_name column is required')

    return valid


def validate_exist_file(reader: DictReader):
    field_names = reader.fieldnames

    if 'email' not in field_names:
        print('email column is required')
        return False

    return True


def search(client: EmailHunterClient, domain, offset, type_, print_header=True, is_file_output=False):
    if is_file_output:
        header = 'domain,email,type,sources'
        line_format = '{},{},{},{}'
    else:
        header = 'Domain\tEmail\tType\tSources'
        line_format = '{}\t{}\t{}\t{}'

    try:
        emails = client.search(domain, offset, type_)
    except Exception as e:
        print('Error during search request: {}'.format(e))
    else:
        for data in emails:
            email = data['value']
            type_ = data['type']
            sources = reduce_sources(data['sources'])

            if print_header:
                print(header)
                print_header = False

            print(line_format.format(domain, email, type_, sources))


def generate(client: EmailHunterClient, domain, first_name, last_name, print_header=True, is_file_output=False):
    try:
        email, score = client.generate(domain, first_name, last_name)
    except Exception as e:
        print('Error during request: {}'.format(e))
    else:
        if is_file_output:
            if print_header:
                print('domain,first_name,last_name,email,score')

            print('{},{},{},{},{}'.format(domain, first_name, last_name, email, score))
        else:
            print('Domain:\t{}'.format(domain))
            print('First Name:\t{}'.format(first_name))
            print('Last Name:\t{}'.format(last_name))
            print('Email:\t{}'.format(email))
            print('Score:\t{}'.format(score))


def exist(client: EmailHunterClient, email, print_header=True, is_file_output=False):
    try:
        exist_, sources = client.exist(email)
    except Exception as e:
        print('Error during exist request: {}'.format(e))
    else:
        if is_file_output:
            if print_header:
                print('email,exist,sources')

            sources = reduce_sources(sources)
            print('{},{},{}'.format(email, exist_, sources))
        else:
            print('Email:\t{}'.format(email))
            print('Exist:\t{}'.format(exist_))
            print('Sources:\t{}'.format(json.dumps(sources, indent=2)))


def handle_search_file(client: EmailHunterClient, reader: DictReader):
    if not validate_search_file(reader):
        return

    print_header = True

    for line in reader:
        domain = line['domain'].strip()
        offset = line.get('offset', 0)
        type_ = line.get('type')
        search(client, domain, offset, type_, print_header=print_header, is_file_output=True)
        print_header = False
        time.sleep(THROTTLE)


def handle_generate_file(client: EmailHunterClient, reader: DictReader):
    if not validate_generate_file(reader):
        return

    print_header = True

    for line in reader:
        domain = line['domain'].strip()
        first_name = line['first_name'].strip()
        last_name = line['last_name'].strip()
        generate(client, domain, first_name, last_name, print_header=print_header, is_file_output=True)
        print_header = False
        time.sleep(THROTTLE)


def handle_exist_file(client: EmailHunterClient, reader: DictReader):
    if not validate_exist_file(reader):
        return

    print_header = True

    for line in reader:
        email = line['email']
        exist(client, email, print_header=print_header, is_file_output=True)
        print_header = False
        time.sleep(THROTTLE)


def handle_cli(command, api_key, domain=None, offset=0, type=None, first_name=None, last_name=None, email=None,
               file=None):
    client = EmailHunterClient(api_key)
    reader = None

    if file is not None:
        file = open(file)
        reader = DictReader(file)

    if command == 'search':
        if file:
            handle_search_file(client, reader)
        elif domain:
            print('Searching {} for emails'.format(domain))

            if offset:
                print('Offset: {}'.format(offset))

            if type:
                print('Type: {}'.format(type))

            search(client, domain, offset, type)
        else:
            print('domain is required when using the generate command')
    elif command == 'generate':
        if file:
            handle_generate_file(client, reader)
        else:
            valid = True

            if not domain:
                print('domain is required when using the generate command')

            if not first_name:
                print('first_name is required when using the generate command')

            if not last_name:
                print('last_name is required when using the generate command')

            if valid:
                print('Finding email for {}, {}, {}'.format(domain, first_name, last_name))
                generate(client, domain, first_name, last_name)
    elif command == 'exist':
        if file:
            handle_exist_file(client, reader)
        elif email:
            print('Checking if {} exists'.format(email))
            exist(client, email)
        else:
            print('email is required when using the exist command')
    else:
        print('Invalid command {}'.format(command))

    if file:
        file.close()


def main():
    """
    TODO: parse args here
    :return:
    """
    parser = argparse.ArgumentParser(description='Email Hunter CLI')
    parser.add_argument('command', help='The API command to run. Choices: search, exist, or generate')
    parser.add_argument('api_key', help='The API key for your account')
    parser.add_argument('--domain', help='Required for search and generate commands')
    parser.add_argument('--offset', help='Optional, used with search command.')
    parser.add_argument('--type', help='Optional, used with search command')
    parser.add_argument('--first_name', help='Required for generate command')
    parser.add_argument('--last_name', help='Required for generate command')
    parser.add_argument('--email', help='Required for exist command')
    file_help = 'Path to a CSV to be used with the specified command. CSV must have a column for each argument used'
    parser.add_argument('--file', help=file_help)
    args = parser.parse_args()

    handle_cli(**vars(args))


if __name__ == '__main__':
    main()
