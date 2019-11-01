from flask import Flask

from __init__ import db, login_manager
from views import view

app = Flask(__name__)

# Routing
app.register_blueprint(view)

# Config
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://{username}:{password}@{host}:{port}/{database}'\
    .format(
        username='postgres',
        password='killer11',
        host='localhost',
        port=5432,
        database='postgres'
    )
app.config['SECRET_KEY'] = 'A random key to use CRF for forms'

# Initialize other components
db.init_app(app)
login_manager.init_app(app)

if __name__ == "__main__":
    app.run(
        debug=True,
        host='localhost',
        port=5000
    )
