# Generated TypeScript README
This README will guide you through the process of using the generated JavaScript SDK package for the connector `example`. It will also provide examples on how to use your generated SDK to call your Data Connect queries and mutations.

***NOTE:** This README is generated alongside the generated SDK. If you make changes to this file, they will be overwritten when the SDK is regenerated.*

# Table of Contents
- [**Overview**](#generated-javascript-readme)
- [**Accessing the connector**](#accessing-the-connector)
  - [*Connecting to the local Emulator*](#connecting-to-the-local-emulator)
- [**Queries**](#queries)
  - [*ListPublicLists*](#listpubliclists)
  - [*GetMyWatchHistory*](#getmywatchhistory)
- [**Mutations**](#mutations)
  - [*CreatePublicList*](#createpubliclist)
  - [*AddMovieToList*](#addmovietolist)

# Accessing the connector
A connector is a collection of Queries and Mutations. One SDK is generated for each connector - this SDK is generated for the connector `example`. You can find more information about connectors in the [Data Connect documentation](https://firebase.google.com/docs/data-connect#how-does).

You can use this generated SDK by importing from the package `@dataconnect/generated` as shown below. Both CommonJS and ESM imports are supported.

You can also follow the instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#set-client).

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
```

## Connecting to the local Emulator
By default, the connector will connect to the production service.

To connect to the emulator, you can use the following code.
You can also follow the emulator instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#instrument-clients).

```typescript
import { connectDataConnectEmulator, getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
connectDataConnectEmulator(dataConnect, 'localhost', 9399);
```

After it's initialized, you can call your Data Connect [queries](#queries) and [mutations](#mutations) from your generated SDK.

# Queries

There are two ways to execute a Data Connect Query using the generated Web SDK:
- Using a Query Reference function, which returns a `QueryRef`
  - The `QueryRef` can be used as an argument to `executeQuery()`, which will execute the Query and return a `QueryPromise`
- Using an action shortcut function, which returns a `QueryPromise`
  - Calling the action shortcut function will execute the Query and return a `QueryPromise`

The following is true for both the action shortcut function and the `QueryRef` function:
- The `QueryPromise` returned will resolve to the result of the Query once it has finished executing
- If the Query accepts arguments, both the action shortcut function and the `QueryRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Query
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each query. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-queries).

## ListPublicLists
You can execute the `ListPublicLists` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
listPublicLists(): QueryPromise<ListPublicListsData, undefined>;

interface ListPublicListsRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<ListPublicListsData, undefined>;
}
export const listPublicListsRef: ListPublicListsRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
listPublicLists(dc: DataConnect): QueryPromise<ListPublicListsData, undefined>;

interface ListPublicListsRef {
  ...
  (dc: DataConnect): QueryRef<ListPublicListsData, undefined>;
}
export const listPublicListsRef: ListPublicListsRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the listPublicListsRef:
```typescript
const name = listPublicListsRef.operationName;
console.log(name);
```

### Variables
The `ListPublicLists` query has no variables.
### Return Type
Recall that executing the `ListPublicLists` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `ListPublicListsData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface ListPublicListsData {
  lists: ({
    id: UUIDString;
    name: string;
    description?: string | null;
  } & List_Key)[];
}
```
### Using `ListPublicLists`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, listPublicLists } from '@dataconnect/generated';


// Call the `listPublicLists()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await listPublicLists();

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await listPublicLists(dataConnect);

console.log(data.lists);

// Or, you can use the `Promise` API.
listPublicLists().then((response) => {
  const data = response.data;
  console.log(data.lists);
});
```

### Using `ListPublicLists`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, listPublicListsRef } from '@dataconnect/generated';


// Call the `listPublicListsRef()` function to get a reference to the query.
const ref = listPublicListsRef();

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = listPublicListsRef(dataConnect);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.lists);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.lists);
});
```

## GetMyWatchHistory
You can execute the `GetMyWatchHistory` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
getMyWatchHistory(): QueryPromise<GetMyWatchHistoryData, undefined>;

interface GetMyWatchHistoryRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<GetMyWatchHistoryData, undefined>;
}
export const getMyWatchHistoryRef: GetMyWatchHistoryRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
getMyWatchHistory(dc: DataConnect): QueryPromise<GetMyWatchHistoryData, undefined>;

interface GetMyWatchHistoryRef {
  ...
  (dc: DataConnect): QueryRef<GetMyWatchHistoryData, undefined>;
}
export const getMyWatchHistoryRef: GetMyWatchHistoryRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the getMyWatchHistoryRef:
```typescript
const name = getMyWatchHistoryRef.operationName;
console.log(name);
```

### Variables
The `GetMyWatchHistory` query has no variables.
### Return Type
Recall that executing the `GetMyWatchHistory` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `GetMyWatchHistoryData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface GetMyWatchHistoryData {
  watches: ({
    id: UUIDString;
    movie: {
      id: UUIDString;
      title: string;
      year: number;
    } & Movie_Key;
      watchDate: DateString;
      location?: string | null;
  } & Watch_Key)[];
}
```
### Using `GetMyWatchHistory`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, getMyWatchHistory } from '@dataconnect/generated';


// Call the `getMyWatchHistory()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await getMyWatchHistory();

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await getMyWatchHistory(dataConnect);

console.log(data.watches);

// Or, you can use the `Promise` API.
getMyWatchHistory().then((response) => {
  const data = response.data;
  console.log(data.watches);
});
```

### Using `GetMyWatchHistory`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, getMyWatchHistoryRef } from '@dataconnect/generated';


// Call the `getMyWatchHistoryRef()` function to get a reference to the query.
const ref = getMyWatchHistoryRef();

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = getMyWatchHistoryRef(dataConnect);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.watches);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.watches);
});
```

# Mutations

There are two ways to execute a Data Connect Mutation using the generated Web SDK:
- Using a Mutation Reference function, which returns a `MutationRef`
  - The `MutationRef` can be used as an argument to `executeMutation()`, which will execute the Mutation and return a `MutationPromise`
- Using an action shortcut function, which returns a `MutationPromise`
  - Calling the action shortcut function will execute the Mutation and return a `MutationPromise`

The following is true for both the action shortcut function and the `MutationRef` function:
- The `MutationPromise` returned will resolve to the result of the Mutation once it has finished executing
- If the Mutation accepts arguments, both the action shortcut function and the `MutationRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Mutation
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each mutation. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-mutations).

## CreatePublicList
You can execute the `CreatePublicList` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
createPublicList(vars: CreatePublicListVariables): MutationPromise<CreatePublicListData, CreatePublicListVariables>;

interface CreatePublicListRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: CreatePublicListVariables): MutationRef<CreatePublicListData, CreatePublicListVariables>;
}
export const createPublicListRef: CreatePublicListRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
createPublicList(dc: DataConnect, vars: CreatePublicListVariables): MutationPromise<CreatePublicListData, CreatePublicListVariables>;

interface CreatePublicListRef {
  ...
  (dc: DataConnect, vars: CreatePublicListVariables): MutationRef<CreatePublicListData, CreatePublicListVariables>;
}
export const createPublicListRef: CreatePublicListRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the createPublicListRef:
```typescript
const name = createPublicListRef.operationName;
console.log(name);
```

### Variables
The `CreatePublicList` mutation requires an argument of type `CreatePublicListVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface CreatePublicListVariables {
  name: string;
  description: string;
}
```
### Return Type
Recall that executing the `CreatePublicList` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `CreatePublicListData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface CreatePublicListData {
  list_insert: List_Key;
}
```
### Using `CreatePublicList`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, createPublicList, CreatePublicListVariables } from '@dataconnect/generated';

// The `CreatePublicList` mutation requires an argument of type `CreatePublicListVariables`:
const createPublicListVars: CreatePublicListVariables = {
  name: ..., 
  description: ..., 
};

// Call the `createPublicList()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await createPublicList(createPublicListVars);
// Variables can be defined inline as well.
const { data } = await createPublicList({ name: ..., description: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await createPublicList(dataConnect, createPublicListVars);

console.log(data.list_insert);

// Or, you can use the `Promise` API.
createPublicList(createPublicListVars).then((response) => {
  const data = response.data;
  console.log(data.list_insert);
});
```

### Using `CreatePublicList`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, createPublicListRef, CreatePublicListVariables } from '@dataconnect/generated';

// The `CreatePublicList` mutation requires an argument of type `CreatePublicListVariables`:
const createPublicListVars: CreatePublicListVariables = {
  name: ..., 
  description: ..., 
};

// Call the `createPublicListRef()` function to get a reference to the mutation.
const ref = createPublicListRef(createPublicListVars);
// Variables can be defined inline as well.
const ref = createPublicListRef({ name: ..., description: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = createPublicListRef(dataConnect, createPublicListVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.list_insert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.list_insert);
});
```

## AddMovieToList
You can execute the `AddMovieToList` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
addMovieToList(vars: AddMovieToListVariables): MutationPromise<AddMovieToListData, AddMovieToListVariables>;

interface AddMovieToListRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddMovieToListVariables): MutationRef<AddMovieToListData, AddMovieToListVariables>;
}
export const addMovieToListRef: AddMovieToListRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
addMovieToList(dc: DataConnect, vars: AddMovieToListVariables): MutationPromise<AddMovieToListData, AddMovieToListVariables>;

interface AddMovieToListRef {
  ...
  (dc: DataConnect, vars: AddMovieToListVariables): MutationRef<AddMovieToListData, AddMovieToListVariables>;
}
export const addMovieToListRef: AddMovieToListRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the addMovieToListRef:
```typescript
const name = addMovieToListRef.operationName;
console.log(name);
```

### Variables
The `AddMovieToList` mutation requires an argument of type `AddMovieToListVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface AddMovieToListVariables {
  listId: UUIDString;
  movieId: UUIDString;
  position: number;
  note?: string | null;
}
```
### Return Type
Recall that executing the `AddMovieToList` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `AddMovieToListData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface AddMovieToListData {
  listItem_insert: ListItem_Key;
}
```
### Using `AddMovieToList`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, addMovieToList, AddMovieToListVariables } from '@dataconnect/generated';

// The `AddMovieToList` mutation requires an argument of type `AddMovieToListVariables`:
const addMovieToListVars: AddMovieToListVariables = {
  listId: ..., 
  movieId: ..., 
  position: ..., 
  note: ..., // optional
};

// Call the `addMovieToList()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await addMovieToList(addMovieToListVars);
// Variables can be defined inline as well.
const { data } = await addMovieToList({ listId: ..., movieId: ..., position: ..., note: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await addMovieToList(dataConnect, addMovieToListVars);

console.log(data.listItem_insert);

// Or, you can use the `Promise` API.
addMovieToList(addMovieToListVars).then((response) => {
  const data = response.data;
  console.log(data.listItem_insert);
});
```

### Using `AddMovieToList`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, addMovieToListRef, AddMovieToListVariables } from '@dataconnect/generated';

// The `AddMovieToList` mutation requires an argument of type `AddMovieToListVariables`:
const addMovieToListVars: AddMovieToListVariables = {
  listId: ..., 
  movieId: ..., 
  position: ..., 
  note: ..., // optional
};

// Call the `addMovieToListRef()` function to get a reference to the mutation.
const ref = addMovieToListRef(addMovieToListVars);
// Variables can be defined inline as well.
const ref = addMovieToListRef({ listId: ..., movieId: ..., position: ..., note: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = addMovieToListRef(dataConnect, addMovieToListVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.listItem_insert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.listItem_insert);
});
```

