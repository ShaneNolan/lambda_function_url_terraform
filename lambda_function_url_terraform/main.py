import json
from typing import Any, Dict


def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """Simple Lambda function to return a message and `200` status code."""
    return {
        'body': json.dumps({'message': 'More articles on blog.shanenolan.dev'}),
        'statusCode': 200,
    }
