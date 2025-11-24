import { queryRef, executeQuery, mutationRef, executeMutation, validateArgs } from 'firebase/data-connect';

export const connectorConfig = {
  connector: 'example',
  service: 'houseofsheelaa',
  location: 'us-east4'
};

export const createPublicListRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'CreatePublicList', inputVars);
}
createPublicListRef.operationName = 'CreatePublicList';

export function createPublicList(dcOrVars, vars) {
  return executeMutation(createPublicListRef(dcOrVars, vars));
}

export const listPublicListsRef = (dc) => {
  const { dc: dcInstance} = validateArgs(connectorConfig, dc, undefined);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'ListPublicLists');
}
listPublicListsRef.operationName = 'ListPublicLists';

export function listPublicLists(dc) {
  return executeQuery(listPublicListsRef(dc));
}

export const addMovieToListRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'AddMovieToList', inputVars);
}
addMovieToListRef.operationName = 'AddMovieToList';

export function addMovieToList(dcOrVars, vars) {
  return executeMutation(addMovieToListRef(dcOrVars, vars));
}

export const getMyWatchHistoryRef = (dc) => {
  const { dc: dcInstance} = validateArgs(connectorConfig, dc, undefined);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetMyWatchHistory');
}
getMyWatchHistoryRef.operationName = 'GetMyWatchHistory';

export function getMyWatchHistory(dc) {
  return executeQuery(getMyWatchHistoryRef(dc));
}

