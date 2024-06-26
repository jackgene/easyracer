module EasyRacer.Scenario7 exposing (main)

import EasyRacer.Ports as Ports
import Http
import Platform exposing (Program)
import Process
import Set exposing (Set)
import Task


type alias Flags =
    String


type alias Model =
    { inflightTrackers : Set String
    }


type Msg
    = HttpResponse String (Result Http.Error String)
    | Perform (Cmd Msg)


scenarioPath : String
scenarioPath =
    "/7"


init : Flags -> ( Model, Cmd Msg )
init baseUrl =
    let
        requestTrackersAndDelays =
            [ ( "first", Nothing ), ( "second", Just 3000 ) ]

        httpRequest tracker =
            { method = "GET"
            , headers = []
            , url = baseUrl ++ scenarioPath
            , body = Http.emptyBody
            , expect = Http.expectString (HttpResponse tracker)
            , timeout = Nothing
            , tracker = Just tracker
            }
    in
    ( { inflightTrackers =
            requestTrackersAndDelays
                |> List.map Tuple.first
                |> Set.fromList
      }
    , requestTrackersAndDelays
        |> List.map
            (\( tracker, maybeDelay ) ->
                let
                    httpReqCmd : Cmd Msg
                    httpReqCmd =
                        Http.request <| httpRequest <| tracker
                in
                case maybeDelay of
                    Just delay ->
                        Process.sleep delay |> Task.perform (\_ -> Perform httpReqCmd)

                    Nothing ->
                        httpReqCmd
            )
        |> Cmd.batch
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HttpResponse tracker httpResult ->
            let
                remainingTrackers : Set String
                remainingTrackers =
                    model.inflightTrackers |> Set.remove tracker
            in
            ( { model | inflightTrackers = remainingTrackers }
            , case httpResult of
                Ok bodyText ->
                    let
                        cancellations : List (Cmd Msg)
                        cancellations =
                            remainingTrackers
                                |> Set.toList
                                |> List.map Http.cancel

                        returnResult : Cmd Msg
                        returnResult =
                            Ok bodyText |> Ports.sendResult
                    in
                    returnResult :: cancellations |> Cmd.batch

                Err _ ->
                    if not <| Set.isEmpty remainingTrackers then
                        Cmd.none

                    else
                        Err "all requests completed without a single success response" |> Ports.sendResult
            )

        Perform cmd ->
            ( model, cmd )


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = always Sub.none
        }
