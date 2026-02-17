import os
from app import create_app, db
from app.models.user_model import User
from app.models.product_model import Product

# When running in a container, the 'app' directory is the current working directory
app = create_app(os.getenv('FLASK_CONFIG') or 'default')

@app.shell_context_processor
def make_shell_context():
    """
    Creates a shell context that adds the database and models to the shell session.
    """
    return dict(db=db, User=User, Product=Product)

if __name__ == '__main__':
app.run(host='0.0.0.0', port=80)    
     