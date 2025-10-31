# test_ai_chat_py.py
import unittest
import subprocess
import json

SCRIPT_PATH = "../ai-chat-py.py"  # Adjust if script is elsewhere

class TestAiChatPy(unittest.TestCase):

    def run_script(self, input_json):
        """Helper to run the script with input JSON as argument and return decoded output."""
        result = subprocess.run(
            ["python3", SCRIPT_PATH, input_json],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        try:
            return json.loads(result.stdout.strip())
        except json.JSONDecodeError:
            self.fail(f"Invalid JSON output: {result.stdout}")

    def test_valid_message(self):
        payload = {"message": "Hello from Downers Grove"}
        output = self.run_script(json.dumps(payload))
        self.assertIn("reply", output)
        self.assertIn("Eiffel Tower", output["reply"])
        self.assertEqual(output.get("debug"), "mock_with_msgspec")

    def test_empty_message(self):
        payload = {"message": ""}
        output = self.run_script(json.dumps(payload))
        self.assertIn("reply", output)
        self.assertIn("didn't catch that", output["reply"])
        self.assertEqual(output.get("debug"), "mock_with_msgspec")

    def test_no_input(self):
        output = subprocess.run(
            ["python3", SCRIPT_PATH],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        parsed = json.loads(output.stdout.strip())
        self.assertIn("reply", parsed)
        self.assertIn("no input received", parsed["reply"])
        self.assertEqual(parsed.get("debug"), "no_input")

    def test_invalid_json(self):
        output = self.run_script("{bad_json: true}")
        self.assertNotIn("reply", output)
        self.assertEqual(output.get("error"), "invalid_input")
        self.assertIn("details", output)

if __name__ == "__main__":
    unittest.main()
