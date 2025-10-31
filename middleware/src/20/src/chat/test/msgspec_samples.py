import msgspec

def msgspec_simple():
    data = {"name": "Brandon", "role": "Cloud Engineer"}
    # Encode to JSON
    encoded = msgspec.json.encode(data)
    print(encoded)  # b'{"name":"Brandon","role":"Cloud Engineer"}'
    # Decode from JSON
    decoded = msgspec.json.decode(encoded)
    print(decoded)  # {'name': 'Brandon', 'role': 'Cloud Engineer'}

def msgspec_object():
    class Dog(msgspec.Struct):
        legs: int
        collar: str
    class User(msgspec.Struct):
        name: str
        age: int
        active: bool = True  # default value

    # Decode JSON into a typed struct
    json_data = b'{"name": "Brandon", "age": 35}'
    user = msgspec.json.decode(json_data, type=User)
    print(f"user isa {type(user)}\n\t{user}")  # User(name='Brandon', age=35, active=True)
    # Encode back to JSON
    user_bytes = msgspec.json.encode(user)
    print(user_bytes)  # b'{"name":"Brandon","age":35,"active":true}'

    # Instantiate the struct
    charlie = Dog(legs=4, collar="red")
    print(f"charlie isa {type(charlie)}\n\t{charlie}")  # User(name='Brandon', age=35, active=True)
    # Serialize to JSON
    charlie_json_bytes = msgspec.json.encode(charlie)
    print(charlie_json_bytes)  # b'{"name":"Brandon","age":35,"active":true}'
    # If you want a string instead of bytes:
    json_str = charlie_json_bytes.decode("utf-8")
    print(json_str)  # {"name":"Brandon","age":35,"active":true}

def main():
    print("Running msgspec examples...")
    # msgspec_simple()
    msgspec_object()

if __name__ == '__main__':
    main()
