from os import path
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, current_user, login_required, login_user
from website.dotenv import get_db_settings_string
from flask import (
    Flask, flash, g, jsonify, redirect, render_template,
    request, session, url_for, Blueprint
)
import json
import sqlite3
import re

app = Flask(__name__)

# To run properly -> configure dotenv.py to your own PSQL settings
app.config['SQLALCHEMY_DATABASE_URI'] = get_db_settings_string()

app.config['SECRET_KEY'] = 'A random key to use CRF for forms'

ROOT = path.dirname(path.realpath(__file__))

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get("user_id") is None:
            return redirect("/login")
        return f(*args, **kwargs)
    return decorated_function

db = SQLAlchemy()
login_manager = LoginManager()
db.init_app(app)
login_manager.init_app(app)

"""
ROUTES
"""
@app.route("/")
def index():
    return render_template("index.html")

@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        form = request.form
        username = form["username"]
        password = form["password"]
        email = form["email"]
        query = f"SELECT * FROM Account WHERE username = '{username}'"
        user_exists = db.session.execute(query).fetchone()
        if user_exists:
            return render_template("signup.html", data = {
                "message": "That username already exists..."
            })
        else:
            query = f"INSERT INTO Account(username, password, email) \
                VALUES ('{username}', '{password}', '{email}')"
            db.session.execute(query)
            db.session.commit()
            return redirect("/", data = {
                "message": "Registered!"
            })
    else:
        return render_template("signup.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    session.clear()
    if request.method == "POST":
        form = request.form
        username = form["username"]
        password = form["password"]
        query = f"SELECT * FROM Account \
            WHERE username = '{username}' AND password = '{password}'"
        user_exists = db.session.execute(query).fetchone()
        if user_exists:
            session["username"] = username
            return redirect("/", data = {
                "message": f"Welcome, {username}"
            })
        else:
            return render_template("login.html", data = {
                "message": "That user does not exist..."
            })
    else:
        return render_template("login.html")

""" Main Function """
if __name__ == "__main__":
    app.run(
        debug=True,
        host='localhost',
        port=5000
    )
