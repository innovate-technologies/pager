package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/sfreiberg/gotwilio"
)

// config
var twilioAccountSID = os.Getenv("TWILIO_ACCOUNT_SID")
var twilioAccountAuthToken = os.Getenv("TWILIO_ACCOUNT_AUTH_TOKEN")
var twilioNumber = os.Getenv("TWILIO_NUMBER")
var pagerNumber = os.Getenv("PAGER_NUMBER")
var slackToken = os.Getenv("SLACK_TOKEN")

type slackResponse struct {
	Username     string `json:"username"`
	IconEmoji    string `json:"icon_emoji"`
	ResponseType string `json:"response_type"`
	Text         string `json:"text"`
}

func main() {
	lambda.Start(handleRequest)
}

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if request.QueryStringParameters["token"] != slackToken {
		return events.APIGatewayProxyResponse{Body: "Invalid token", StatusCode: http.StatusUnauthorized, Headers: map[string]string{"Content-Type": "text/plain"}}, nil
	}

	message := fmt.Sprintf("(#%s) @%s: %s", request.QueryStringParameters["channel_name"], request.QueryStringParameters["user_name"], request.QueryStringParameters["text"])
	sendSMS(message)

	response := slackResponse{
		Username:     "Pager",
		IconEmoji:    ":pager:",
		ResponseType: "in_channel",
		Text:         "Alert has been send!",
	}
	responseBytes, _ := json.Marshal(response)

	return events.APIGatewayProxyResponse{Body: string(responseBytes), StatusCode: 200, Headers: map[string]string{"Content-Type": "application/json"}}, nil
}

func sendSMS(message string) {
	twilio := gotwilio.NewTwilioClient(twilioAccountSID, twilioAccountAuthToken)
	twilio.SendSMS(twilioNumber, pagerNumber, message, "", "")
}
