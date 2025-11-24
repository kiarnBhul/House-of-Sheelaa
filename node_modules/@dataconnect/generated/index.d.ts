import { ConnectorConfig, DataConnect, QueryRef, QueryPromise, MutationRef, MutationPromise } from 'firebase/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;




export interface AddMovieToListData {
  listItem_insert: ListItem_Key;
}

export interface AddMovieToListVariables {
  listId: UUIDString;
  movieId: UUIDString;
  position: number;
  note?: string | null;
}

export interface CreatePublicListData {
  list_insert: List_Key;
}

export interface CreatePublicListVariables {
  name: string;
  description: string;
}

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

export interface ListItem_Key {
  listId: UUIDString;
  movieId: UUIDString;
  __typename?: 'ListItem_Key';
}

export interface ListPublicListsData {
  lists: ({
    id: UUIDString;
    name: string;
    description?: string | null;
  } & List_Key)[];
}

export interface List_Key {
  id: UUIDString;
  __typename?: 'List_Key';
}

export interface Movie_Key {
  id: UUIDString;
  __typename?: 'Movie_Key';
}

export interface Review_Key {
  id: UUIDString;
  __typename?: 'Review_Key';
}

export interface User_Key {
  id: UUIDString;
  __typename?: 'User_Key';
}

export interface Watch_Key {
  id: UUIDString;
  __typename?: 'Watch_Key';
}

interface CreatePublicListRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: CreatePublicListVariables): MutationRef<CreatePublicListData, CreatePublicListVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: CreatePublicListVariables): MutationRef<CreatePublicListData, CreatePublicListVariables>;
  operationName: string;
}
export const createPublicListRef: CreatePublicListRef;

export function createPublicList(vars: CreatePublicListVariables): MutationPromise<CreatePublicListData, CreatePublicListVariables>;
export function createPublicList(dc: DataConnect, vars: CreatePublicListVariables): MutationPromise<CreatePublicListData, CreatePublicListVariables>;

interface ListPublicListsRef {
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<ListPublicListsData, undefined>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect): QueryRef<ListPublicListsData, undefined>;
  operationName: string;
}
export const listPublicListsRef: ListPublicListsRef;

export function listPublicLists(): QueryPromise<ListPublicListsData, undefined>;
export function listPublicLists(dc: DataConnect): QueryPromise<ListPublicListsData, undefined>;

interface AddMovieToListRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddMovieToListVariables): MutationRef<AddMovieToListData, AddMovieToListVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: AddMovieToListVariables): MutationRef<AddMovieToListData, AddMovieToListVariables>;
  operationName: string;
}
export const addMovieToListRef: AddMovieToListRef;

export function addMovieToList(vars: AddMovieToListVariables): MutationPromise<AddMovieToListData, AddMovieToListVariables>;
export function addMovieToList(dc: DataConnect, vars: AddMovieToListVariables): MutationPromise<AddMovieToListData, AddMovieToListVariables>;

interface GetMyWatchHistoryRef {
  /* Allow users to create refs without passing in DataConnect */
  (): QueryRef<GetMyWatchHistoryData, undefined>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect): QueryRef<GetMyWatchHistoryData, undefined>;
  operationName: string;
}
export const getMyWatchHistoryRef: GetMyWatchHistoryRef;

export function getMyWatchHistory(): QueryPromise<GetMyWatchHistoryData, undefined>;
export function getMyWatchHistory(dc: DataConnect): QueryPromise<GetMyWatchHistoryData, undefined>;

