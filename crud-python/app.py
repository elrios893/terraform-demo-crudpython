import time
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
import mysql.connector
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
CORS(app)

def get_db():
    for i in range(30):
        try:
            db = mysql.connector.connect(
                host=os.getenv("DB_HOST"),
                user=os.getenv("DB_USER"),
                password=os.getenv("DB_PASSWORD"),
                database=os.getenv("DB_NAME")
            )
            return db
        except mysql.connector.Error as e:
            print(f"Intento {i+1}: No se pudo conectar a MySQL - {e}")
            time.sleep(2)
    raise Exception("No se pudo conectar a MySQL despues de 30 intentos")

db = get_db()
cursor = db.cursor(dictionary=True)

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/usuarios', methods=['GET'])
def obtener_usuarios():
    cursor.execute("SELECT * FROM usuarios")
    usuarios = cursor.fetchall()
    return jsonify(usuarios)

@app.route('/usuarios', methods=['POST'])
def crear_usuario():
    data = request.json
    sql = "INSERT INTO usuarios(nombre, correo) VALUES (%s, %s)"
    values = (data['nombre'], data['correo'])
    cursor.execute(sql, values)
    db.commit()
    return jsonify({"mensaje": "Usuario creado"})

@app.route('/usuarios/<int:id>', methods=['DELETE'])
def eliminar_usuario(id):
    sql = "DELETE FROM usuarios WHERE id = %s"
    cursor.execute(sql, (id,))
    db.commit()
    return jsonify({"mensaje": "Usuario eliminado"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
