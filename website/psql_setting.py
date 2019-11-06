USERNAME = 'postgres'
PASSWORD_TO_DB = 'postgres'
HOST_NAME = 'localhost'
PORT_NUMBER = 5432
DATABASE_NAME = 'postgres'

def get_db_settings_string():
    username = USERNAME
    password = PASSWORD_TO_DB
    host = HOST_NAME
    port = PORT_NUMBER
    database = DATABASE_NAME
    return f'postgresql://{username}:{password}@{host}:{port}/{database}'
