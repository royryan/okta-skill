// Management API with @okta/okta-sdk-nodejs (v7+), private-key JWT auth.
// Source pattern: github.com/okta/okta-sdk-nodejs README.
// npm i @okta/okta-sdk-nodejs

const okta = require('@okta/okta-sdk-nodejs');

const client = new okta.Client({
  orgUrl: process.env.OKTA_CLIENT_ORGURL,          // https://dev-123456.okta.com
  authorizationMode: 'PrivateKey',
  clientId: process.env.OKTA_CLIENT_ID,
  scopes: ['okta.users.manage', 'okta.groups.manage'],
  privateKey: process.env.OKTA_CLIENT_PRIVATEKEY,  // PEM or JWK JSON
  keyId: process.env.OKTA_CLIENT_KEYID,
});

async function main() {
  // Create an activated user
  const { user } = await client.userApi.createUser({
    body: {
      profile: {
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        login: 'ada@example.com',
      },
    },
    activate: true,
  });
  console.log('created', user.id);

  // Indexed search (preferred over filter/q)
  const engineers = await client.userApi.listUsers({
    search: 'profile.department eq "Engineering" and status eq "ACTIVE"',
  });
  for await (const u of engineers) {
    console.log('engineer:', u.profile.login);
  }

  // Create a group and add the user
  const group = await client.groupApi.createGroup({
    group: { profile: { name: 'engineering', description: 'Engineering staff' } },
  });
  await client.groupApi.assignUserToGroup({ groupId: group.id, userId: user.id });

  // Assign the group to an app (bulk-friendly: group assignment > per-user)
  // await client.applicationApi.createApplicationGroupAssignment({
  //   appId: 'yourAppId', groupId: group.id, applicationGroupAssignment: {},
  // });

  // Lifecycle: suspend / deactivate
  // await client.userApi.suspendUser({ userId: user.id });
  // await client.userApi.deactivateUser({ userId: user.id });
}

main().catch(err => {
  // Okta error shape: err.status, err.errorCode, err.errorSummary, err.errorCauses
  console.error(err.errorSummary || err);
  process.exit(1);
});
