# Management API with okta-sdk-python, private-key JWT auth.
# Source pattern: github.com/okta/okta-sdk-python README.
# pip install okta

import asyncio
import os
from okta.client import Client as OktaClient

config = {
    "orgUrl": os.environ["OKTA_CLIENT_ORGURL"],  # https://dev-123456.okta.com
    "authorizationMode": "PrivateKey",
    "clientId": os.environ["OKTA_CLIENT_ID"],
    "scopes": ["okta.users.manage", "okta.groups.manage"],
    "privateKey": os.environ["OKTA_CLIENT_PRIVATEKEY"],  # PEM or JWK
}

client = OktaClient(config)


async def main():
    # Create an activated user
    body = {
        "profile": {
            "firstName": "Ada",
            "lastName": "Lovelace",
            "email": "ada@example.com",
            "login": "ada@example.com",
        }
    }
    user, resp, err = await client.create_user(body, query_params={"activate": "true"})
    if err:
        raise RuntimeError(err)
    print("created", user.id)

    # Indexed search + auto-pagination
    users, resp, err = await client.list_users(
        query_params={"search": 'profile.department eq "Engineering"'}
    )
    while True:
        for u in users or []:
            print("engineer:", u.profile.login)
        if not resp.has_next():
            break
        users, err = await resp.next()

    # Group + membership
    group, _, err = await client.create_group(
        {"profile": {"name": "engineering", "description": "Engineering staff"}}
    )
    await client.add_user_to_group(group.id, user.id)

    # Lifecycle examples:
    # await client.suspend_user(user.id)
    # await client.deactivate_or_delete_user(user.id)


if __name__ == "__main__":
    asyncio.run(main())
