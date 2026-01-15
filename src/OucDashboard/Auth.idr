module OucDashboard.Auth

import JS

%default total

-- =============================================================================
-- FFI Bindings for Internet Identity (window.oucAuth)
-- =============================================================================

%foreign "javascript:lambda:() => window.oucAuth ? window.oucAuth.initAuth() : Promise.resolve(null)"
prim__initAuth : PrimIO AnyPtr

%foreign "javascript:lambda:() => window.oucAuth ? window.oucAuth.login() : Promise.resolve(null)"
prim__login : PrimIO AnyPtr

%foreign "javascript:lambda:() => window.oucAuth ? window.oucAuth.logout() : Promise.resolve(undefined)"
prim__logout : PrimIO AnyPtr

%foreign "javascript:lambda:() => window.oucAuth ? window.oucAuth.isAuthenticated() : Promise.resolve(false)"
prim__isAuthenticated : PrimIO AnyPtr

%foreign "javascript:lambda:() => window.oucAuth ? window.oucAuth.getPrincipal() : null"
prim__getPrincipal : PrimIO AnyPtr

-- =============================================================================
-- Promise Handling
-- =============================================================================

%foreign "javascript:lambda:(p, f) => p.then(x => f(x)())"
prim__thenPromise : AnyPtr -> (AnyPtr -> PrimIO ()) -> PrimIO ()

%foreign "javascript:lambda:x => x === null || x === undefined"
prim__isNull : AnyPtr -> Bool

%foreign "javascript:lambda:x => String(x)"
prim__toString : AnyPtr -> String

-- =============================================================================
-- High-Level API
-- =============================================================================

||| Initialize auth client, returns principal if already authenticated
export
initAuth : (Maybe String -> IO ()) -> IO ()
initAuth callback = do
  promise <- primIO prim__initAuth
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    if prim__isNull result
      then callback Nothing
      else callback (Just (prim__toString result))

||| Login with Internet Identity, returns principal on success
export
login : (Maybe String -> IO ()) -> IO ()
login callback = do
  promise <- primIO prim__login
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    if prim__isNull result
      then callback Nothing
      else callback (Just (prim__toString result))

||| Logout from Internet Identity
export
logout : IO () -> IO ()
logout callback = do
  promise <- primIO prim__logout
  primIO $ prim__thenPromise promise $ \_ => toPrim callback

||| Check if authenticated (async)
export
checkAuth : (Bool -> IO ()) -> IO ()
checkAuth callback = do
  promise <- primIO prim__isAuthenticated
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    -- JS boolean to Idris Bool
    callback (not (prim__isNull result) && prim__toString result == "true")

||| Get current principal (sync, returns Nothing if not authenticated)
export
getPrincipal : IO (Maybe String)
getPrincipal = do
  result <- primIO prim__getPrincipal
  if prim__isNull result
    then pure Nothing
    else pure (Just (prim__toString result))
