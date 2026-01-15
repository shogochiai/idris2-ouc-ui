module OucDashboard.Main

import JS
import Web.MVC
import OucDashboard.Model
import OucDashboard.Update
import OucDashboard.View
import OucDashboard.Auth
-- OucDashboard.Indexer provides FFI bindings for window.oucIndexer

%default covering

||| Display function: renders view
||| Note: Actual data fetching will be done via JavaScript callbacks
display : Msg -> Model -> Cmd Msg
display _ model = child Body (view model)

||| Error handler
onError : JSErr -> IO ()
onError err = putStrLn ("Error: " ++ dispErr err)

||| Run the application
export
main : IO ()
main = runMVC update display onError Init initialModel