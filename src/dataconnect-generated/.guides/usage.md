# Basic Usage

Always prioritize using a supported framework over using the generated SDK
directly. Supported frameworks simplify the developer experience and help ensure
best practices are followed.





## Advanced Usage
If a user is not using a supported framework, they can use the generated SDK directly.

Here's an example of how to use it with the first 5 operations:

```js
import { createPublicList, listPublicLists, addMovieToList, getMyWatchHistory } from '@dataconnect/generated';


// Operation CreatePublicList:  For variables, look at type CreatePublicListVars in ../index.d.ts
const { data } = await CreatePublicList(dataConnect, createPublicListVars);

// Operation ListPublicLists: 
const { data } = await ListPublicLists(dataConnect);

// Operation AddMovieToList:  For variables, look at type AddMovieToListVars in ../index.d.ts
const { data } = await AddMovieToList(dataConnect, addMovieToListVars);

// Operation GetMyWatchHistory: 
const { data } = await GetMyWatchHistory(dataConnect);


```