import random
import string
from __init__ import db


names_filename = 'names.txt'
countries_filename = 'countries.txt'
locations_filename = 'locations.txt'

set_up_account_function_name = 'setUpAcct'

PASSWORD_LENGTH = 10
CREDIT_CARD_NUMBER_LENGTH = 16
SEED = 2
random.seed(SEED)



def read(filename):
    res = []
    with open(filename, 'r') as file:
        for line in file.readlines():
            res.append(line.strip())
    return res

usernames = read(names_filename)
countries = read(countries_filename)
locations = read(locations_filename)

print(len(usernames), len(countries), len(locations))
accounts = []

# username, password, email, country, location, credit_card_number, credit_card_exp
for username, country, location in zip(usernames, countries, locations):
    email = f'{username}@demo.com'
    credit_card_exp = '2016-06-23'

    password = ''.join(random.SystemRandom().choice(
        string.ascii_uppercase + string.digits) for _ in range(PASSWORD_LENGTH))

    credit_card_number = ''.join(str(random.randint(0, 9))
                                 for _ in range(CREDIT_CARD_NUMBER_LENGTH))

    include_address = random.choice([True, False])
    include_credit_card = random.choice([True, False])

    account = [username, password, email]

    if include_address:
        account.extend([country, location])
    else:
        account.extend(['NULL', 'NULL'])

    if include_credit_card:
        account.extend([credit_card_number, credit_card_exp])
    else:
        account.extend(['NULL', 'NULL'])

    accounts.append(account)


for account in accounts[:5]:
    arguments = ', '.join(account)
    query = f'CALL {set_up_account_function_name}({arguments});'
    