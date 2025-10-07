package types //types



type LoginReq struct {
	Username string `from:"username" binding:"required"`
	Password string `from:"password" binding:"required"`
}


type RegisterReq struct {
	Username string `from:"username" binding:"required"`
	Password string `from:"password" binding:"required"`
}




