package handler

import (
	"github.com/gin-gonic/gin"
)

type handlerInterface interface {
	login(*gin.Context)
	register(*gin.Context)
}

type Handler struct {
	cognito CognitoClient
	clientID string
}

func NewHandler(cognito CognitoClient, clientID String) *Handler {
	return &Handler{
		cognito: cognito,
		clientID: clientID,
	}
}

func (h *Handler) login(c *gin.Context) {


}


func (h *Handler)  register(c *gin.Context) {


}
