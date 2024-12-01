"""
utils.py

This module provides utility functions for password hashing, validation, and 
input validation. It includes methods to handle common operations such as 
validating user input, hashing passwords, and validating phone numbers or NSU IDs.
"""

import bcrypt
import re

def validate_input(data, required_fields):
    """
    Validates that all required fields are present and non-empty in the input data.

    Args:
        data (dict): The input data to validate.
        required_fields (list): A list of required field names.

    Returns:
        bool: True if all required fields are present and non-empty, False otherwise.
    """
    return all(field in data and data[field] for field in required_fields)


def hash_password(password):
    """
    Hashes a plaintext password using bcrypt.

    Args:
        password (str): The plaintext password to hash.

    Returns:
        str: The hashed password as a string.
    """
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def check_password(password, hashed_password):
    """
    Verifies if a plaintext password matches a given hashed password.

    Args:
        password (str): The plaintext password.
        hashed_password (str): The hashed password to compare against.

    Returns:
        bool: True if the passwords match, False otherwise.
    """
    return bcrypt.checkpw(password.encode("utf-8"), hashed_password.encode("utf-8"))


def is_valid_phone_number(phone_number):
    """
    Validates a Bangladeshi phone number format.

    Args:
        phone_number (str): The phone number to validate.

    Returns:
        bool: True if the phone number matches the format, False otherwise.

    The format ensures:
        - The number starts with '01'.
        - It is followed by 9 digits.
    """
    return re.fullmatch(r"01\d{9}", phone_number) is not None


def is_valid_nsu_id(nsu_id):
    """
    Validates an NSU (North South University) student ID.

    Args:
        nsu_id (str): The NSU ID to validate.

    Returns:
        bool: True if the NSU ID matches the format, False otherwise.

    The format ensures:
        - The ID is a 7-digit number.
    """
    return re.fullmatch(r"\d{7}", nsu_id) is not None
