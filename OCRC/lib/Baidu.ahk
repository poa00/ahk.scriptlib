class Baidu {
	__New(post := "", config := "") {
		clipboard := ""
		this.config := config
		this.Token()
		postdata := "image=" UrlEncode(this.config.imgbase64)
		for key, value in post
			postdata .= "&" key "=" value
		this.json := JSON.Load(URLDownloadToVar("https://aip.baidubce.com/rest/2.0/ocr/v1/" this.config.recogtype "?access_token=" this.token, "UTF-8", "POST", postdata, {"Content-Type":"application/x-www-form-urlencoded"}))
	}

	Show() {
		if this.json.error_msg {
			MsgBox 4112, BaiduOCR ERROR, % this.json.error_msg
			this.Token()
			return
		}

		this.words := this.json.words_result

		id := "baidu" this.json.log_id
		formatstyle  := this.config.formatstyle
		puncstyle  := this.config.puncstyle
		spacestyle  := this.config.spacestyle
		trantype  := this.config.trantype
		searchengine  := this.config.searchengine

		this.Format("")
		this.Punc("")
		this.Space("")
		this.Clip("")
		if this.config.probtype
			this.Prob()

		Gui %id%:New
		Gui %id%:+MinimizeBox
		Gui %id%:Color, EBEDF4
		Gui %id%:Font, s16, Microsoft YaHei

		Gui %id%:Add, Text, x20, 排版
		Gui %id%:Font, s12
		Gui %id%:Add, DropDownList, x+5 w90 hwndformathwnd gFormat AltSubmit Choose%formatstyle%, 智能段落|合并多行|拆分多行
		this.formathwnd := formathwnd
		this.Update(formathwnd, "Format")

		Gui %id%:Font, s16
		Gui %id%:Add, Text, x+15, 标点
		Gui %id%:Font, s12
		Gui %id%:Add, DropDownList, x+5 w90 hwndpunchwnd AltSubmit Choose%puncstyle%, 智能标点|原始结果|中文标点|英文标点
		this.punchwnd := punchwnd
		this.Update(punchwnd, "Punc")

		Gui %id%:Font, s16
		Gui %id%:Add, Text, x+15, 空格
		Gui %id%:Font, s12
		Gui %id%:Add, DropDownList, x+5 w90 hwndspacehwnd AltSubmit Choose%spacestyle%, 智能空格|原始结果|去除空格
		this.spacehwnd := spacehwnd
		this.Update(spacehwnd, "Space")

		Gui %id%:Font, s16
		Gui %id%:Add, Text, x+15, 翻译
		Gui %id%:Font, s12
		Gui %id%:Add, DropDownList, x+5 w90 hwndtranhwnd AltSubmit Choose%trantype%, 自动检测|英⟹中|中⟹英|繁⟹简|日⟹中
		this.tranhwnd := tranhwnd
		this.Update(tranhwnd, "Tran")

		Gui %id%:Font, s16
		Gui %id%:Add, Text, x+15, 搜索
		Gui %id%:Font, s12
		Gui %id%:Add, DropDownList, x+5 w105 hwndsearchhwnd AltSubmit Choose%searchengine%, 百度搜索|谷歌搜索|谷歌镜像|百度百科|维基镜像|Everything
		this.searchhwnd := searchhwnd
		this.Update(searchhwnd, "Search")

		Gui %id%:Font, s18
		Gui %id%:Add, Edit, x20 y50 w760 h400 hwndmainhwnd, % this.result
		this.mainhwnd := mainhwnd
		this.Update(mainhwnd, "Clip")

		if this.config.probtype {
			if (this.probability <= 20)
				progresscolor := "EC4D3D"
			else if (this.probability <= 60)
				progresscolor := "F8CD46"
			else
				progresscolor := "63C956"
			Gui %id%:Add, Progress, x20 y+10 w760 h30 c%progresscolor%, % this.probability
			Gui %id%:Add, Text, yp w800 +Center BackgroundTrans +0x1, % this.probability "%"
		}
		guiheight := this.config.probtype ? 500 : 470
		Gui %id%:Show, w800 h%guiheight%, % "OCRC (BaiduOCR) 「" Baidu_RecogTypesP[this.config.recogtype] "」识别结果"
	}

	Update(hwnd, func) {
		bindfunc := ObjBindMethod(this, func)
		GuiControl +g, %hwnd%, %bindfunc%
	}

	Token() {
		if ReadIni(ConfigFile, "Baidu_Token", "BaiduOCR")
			this.token := ReadIni(ConfigFile, "Baidu_Token", "BaiduOCR")
		else {
			this.token := JSON.Load(URLDownloadToVar("https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=" this.config.api_key "&client_secret=" this.config.secret_key)).access_token
			WriteIni(ConfigFile, this.token, "Baidu_Token", "BaiduOCR")
		}
	}

	Prob() {
		this.probability := 0
		if (this.config.probtype = 1) {
			probadd := 0
			for index, value in this.words
				probadd += value.probability.average * StrLen(value.words)
			this.probability := Format("{:.2f}", 100 * probadd / StrLen(this.result))
		}
		else {
			probadd := 0
			for index, value in this.words
				probadd += value.probability.average
			this.probability := Format("{:.2f}", 100 * probadd / this.json.words_result_num)
		}
	}

	Format(hwnd) {
		if hwnd
			GuiControlGet formatstyle, , %hwnd%
		else
			formatstyle := this.config.formatstyle
		this.result := ""

		if (formatstyle = 1) {
			for index, value in this.json.paragraphs_result {
				for idx, vl in value.words_result_idx
					this.result .= this.words[vl + 1].words
				this.result .= "`n"
			}
		}
		else if (formatstyle = 2) {
			for index, value in this.words
				this.result .= value.words
		}
		else if (formatstyle = 3) {
			for index, value in this.words
				this.result .= value.words "`n"
		}

		this.resulttemp := this.result
		if hwnd
			GuiControl Text, % this.mainhwnd, % this.result
	}

	Punc(hwnd) {
		if hwnd
			GuiControlGet puncstyle, , %hwnd%
		else
			puncstyle := this.config.puncstyle

		if (puncstyle = 1) {
			for c, e in C2EPuncs
				this.result := RegExReplace(this.result, (c ~= "[“‘「『（【《]") ? c IsEnglishAfter : IsEnglishBefore c, e)
			for e, c in E2CPuncs
				this.result := RegExReplace(this.result, (e ~= "[([]") ? ((e ~= "[.?()[\]]") ? "\" e : e) IsChineseAfter : IsChineseBefore ((e ~= "[.?()[\]]") ? "\" e : e), c)
			QPNumP := 1, QPNum := 1, PTR := ""
			result := this.result
			loop parse, result
			{
				if (A_LoopField = """" and (A_Index = 1 or SubStr(this.result, A_Index - 1, 1)) ~= IsChinese and (A_Index = StrLen(this.result) or SubStr(this.result, A_Index + 1, 1) ~= IsChinese))
					PTR .= Mod(QPNumP ++, 2) ? "“" : "”"
				else if (A_LoopField = "'")
					PTR .= Mod(QPNum ++, 2) ? "‘" : "’"
				else
					PTR .= A_LoopField
			}
			this.result := PTR
		}
		else if (puncstyle = 1)
			this.result := this.resultspacetemp
		else if (puncstyle = 3) {
			for EP, CP in E2CPuncs
				this.result := StrReplace(this.result, EP, CP)
		}
		else if (puncstyle = 4) {
			for CP, EP in C2EPuncs
				this.result := StrReplace(this.result, CP, EP)
		}

		this.resultpunctemp := this.result
		if hwnd
			GuiControl Text, % this.mainhwnd, % this.result
	}

	Space(hwnd) {
		if hwnd
			GuiControlGet spacestyle, , %hwnd%
		else
			spacestyle := this.config.spacestyle

		if (spacestyle = 1) {
			for c, e in C2EPuncs
				this.result := RegExReplace(this.result, " ?(" c ") ?", "$1")
			this.result := RegExReplace(this.result, "(?:[\x{4e00}-\x{9fa5}a-zA-Z])\K ?(\d[\d.:]*) ?(?=[\x{4e00}-\x{9fa5}a-zA-Z])", " $1 ")
			this.result := RegExReplace(this.result, "(?:[\x{4e00}-\x{9fa5}a-zA-Z])\K ?(\d[\d.:]*) ?(?![\x{4e00}-\x{9fa5}a-zA-Z])", " $1")
			this.result := RegExReplace(this.result, "(?<![\x{4e00}-\x{9fa5}a-zA-Z]) ?(\d[\d.:]*) ?(?=[\x{4e00}-\x{9fa5}a-zA-Z])", "$1 ")
			this.result := RegExReplace(this.result, "(?:[\x{4e00}-\x{9fa5}])\K ?([a-zA-Z][a-zA-Z-_]*) ?(?=[\x{4e00}-\x{9fa5}])", " $1 ")
			this.result := RegExReplace(this.result, "(?:[\x{4e00}-\x{9fa5}])\K ?([a-zA-Z][a-zA-Z-_]*) ?(?![\x{4e00}-\x{9fa5}])", " $1")
			this.result := RegExReplace(this.result, "(?<![\x{4e00}-\x{9fa5}]) ?([a-zA-Z][a-zA-Z-_]*) ?(?=[\x{4e00}-\x{9fa5}])", "$1 ")
			this.result := RegExReplace(this.result, "(?:[\w\d])\K ?([,.?!:;]) ?(?=[\w\d\x{4e00}-\x{9fa5}])", "$1 ")
			this.result := RegExReplace(this.result, "(?:[\w\d])?\K([([]) ?(?=[\w\d])?", "$1")
			this.result := RegExReplace(this.result, "(?:[\w\d])?\K ?([)\]])(?=[\w\d])?", "$1")
			this.result := RegExReplace(this.result, "(?:\d)\K ?([.:]) ?(?=\d)", "$1")
			PTR := ""
			result := this.result
			loop parse, result, "
			{
				if Mod(A_Index, 2)
					PTR .= A_LoopField """"
				else
					PTR .= Trim(A_LoopField) """"
			}
			this.result := ""
			loop parse, PTR, '
			{
				if Mod(A_Index, 2)
					this.result .= A_LoopField "'"
				else
					this.result .= Trim(A_LoopField) "'"
			}
			this.result := SubStr(this.result, 1, StrLen(this.result) - 2)
		}
		else if (spacestyle = 2)
			this.result := this.resultpunctemp
		else if (spacestyle = 3)
			this.result := StrReplace(this.result, A_Space)

		this.resultspacetemp := this.result
		if hwnd
			GuiControl Text, % this.mainhwnd, % this.result
	}

	Translate(hwnd) {
	}

	Search(hwnd) {
		if hwnd
			GuiControlGet searchengine, , %hwnd%
		else
			searchengine := this.config.searchengine
		result := this.result

		if (searchengine = 6) {
			if (!(result ~= "[*?""<>|]") and result ~= "[C-G]:(?:[\\/].+)+")
				Run D:/Program Files/Everything/Everything.exe -path "%result%"
			else if result
				Run D:/Program Files/Everything/Everything.exe -search "%result%"
			else
				Run D:/Program Files/Everything/Everything.exe -home
		}
		else {
			Run % Baidu_SEnginesP[searchengine] result
			if (searchengine = 3)
				MsgBox 4144, 警告, 请勿在镜像站输入隐私信息！
		}

		this.result := result
	}

	Clip(hwnd) {
		if hwnd {
			GuiControlGet result, , %hwnd%
			this.result := result
		}
		clipboard := this.result
	}
}