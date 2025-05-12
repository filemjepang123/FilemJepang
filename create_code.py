import random
import string

def generate_jav_code():
    prefix = ''.join(random.choices(string.ascii_uppercase, k=4))
    number = random.randint(0, 99)
    return f"{prefix}-{number:03d}"

print(generate_jav_code())
