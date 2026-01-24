module OucDashboard.Main

import JS
import Web.MVC
import OucDashboard.Model
import OucDashboard.Update
import OucDashboard.View
import OucDashboard.Auth
import OucDashboard.Indexer

%default covering

||| Display function: renders view and handles data fetching
display : Msg -> Model -> Cmd Msg
display msg model =
  case msg of
    -- On Init or Refresh, fetch data from OUC Canister
    Init    => batch [child Body (view model), fetchDataCmd]
    Refresh => batch [child Body (view model), fetchDataCmd]
    -- For other messages, just render
    _       => child Body (view model)

||| Error handler
onError : JSErr -> IO ()
onError err = putStrLn ("Error: " ++ dispErr err)

||| Run the application
export
main : IO ()
main = runMVC update display onError Init initialModel
