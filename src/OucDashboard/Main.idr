module OucDashboard.Main

import JS
import Web.MVC
import OucDashboard.Model
import OucDashboard.Update
import OucDashboard.View

%default covering

||| Display function: renders view and returns command
display : Msg -> Model -> Cmd Msg
display _ model = child Body (view model)

||| Error handler
onError : JSErr -> IO ()
onError err = putStrLn ("Error: " ++ dispErr err)

||| Run the application
export
main : IO ()
main = runMVC update display onError Init initialModel