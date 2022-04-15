from lambda_function_url_terraform.main import lambda_handler


def test_lambda_handler() -> None:
    """Ensure the correct response is returned."""
    assert lambda_handler({}, {}) == {
        'body': '{"message": "More articles on blog.shanenolan.dev"}',
        'statusCode': 200,
    }
