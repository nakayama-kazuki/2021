@powershell "$THISFILE=\"%~f0\"; $PSCODE=[scriptblock]::create((Get-Content $THISFILE | Where-Object {$_.readcount -gt 1}) -join \"`n\"); & $PSCODE %*" & goto:eof

<#
	Using this script, you can compress filesize of active pptx (without macro)
	1. remove all Hidden slide
	2. remove all MSO_MEDIA ( and add media name to note )
	3. compress all MSO_PICTURE using export + import
		$COMPRESS_PRECISE : display size (point) * this value, as width & height
		$COMPRESS_FORMAT : if many photos in pptx, ppShapeFormatJPG is recommended
#>

Set-Variable -Name NOTE_SHAPE_IX -Value 2 -Option Constant
Set-Variable -Name PATH_SEPARATOR -Value "\" -Option Constant
Set-Variable -Name VBCRLF -Value "`r`n" -Option Constant
Set-Variable -Name COMPRESS_PRECISE -Value 4 -Option Constant

Set-Variable -Name PP_PICTUREFORMAT_GIF -Value 3 -Option Constant
Set-Variable -Name PP_PICTUREFORMAT_JPG -Value 5 -Option Constant
Set-Variable -Name COMPRESS_FORMAT -Value $PP_PICTUREFORMAT_GIF -Option Constant
#Set-Variable -Name COMPRESS_FORMAT -Value $PP_PICTUREFORMAT_JPG -Option Constant

Set-Variable -Name MSO_GROUP -Value 6 -Option Constant
Set-Variable -Name MSO_PICTURE -Value 13 -Option Constant
Set-Variable -Name MSO_MEDIA -Value 16 -Option Constant

function Ungroup-Shape($in_shape) {
	if ($in_shape.Type -eq $MSO_GROUP) {
		$groupItems = $in_shape.Ungroup()
		foreach ($item in $groupItems) {
			Ungroup-Shape -in_shape $item
		}
	}
}

function Add-Note($in_slide, $in_text) {
	$shape = $in_slide.NotesPage.Shapes.Item($NOTE_SHAPE_IX)
	$shape.TextFrame.TextRange.Text = $in_text + $VBCRLF + $shape.TextFrame.TextRange.Text
}

function Handle-Medias($in_slide) {
	$shapes = $in_slide.Shapes
	for ($i = $shapes.Count; $i -gt 0; $i--) {
		$shape = $shapes.Item($i)
		if ($shape.Type -eq $MSO_MEDIA) {
			Add-Note -in_slide $in_slide -in_text "( removed : $($shape.Name) )"
			$shape.Delete()
		} elseif ($shape.Type -eq $MSO_PICTURE) {
			$tmpPath = [System.IO.Path]::Combine($env:TEMP, "temp.bin")
			$shape.Export($tmpPath, $COMPRESS_FORMAT, $shape.Width * $COMPRESS_PRECISE, $shape.Height * $COMPRESS_PRECISE)
			$added = $in_slide.Shapes.AddPicture($tmpPath, $false, $true, $shape.Left, $shape.Top, $shape.Width, $shape.Height)
			$shape.Delete()
		}
	}
}

$gCom = New-Object -ComObject PowerPoint.Application

$gPresentation = $gCom.ActivePresentation

if (-not $gPresentation) {
	Add-Type -AssemblyName System.Windows.Forms
	[System.Windows.Forms.MessageBox]::Show("pptx is not opened")
} else {
	for ($i = $gPresentation.Slides.Count; $i -gt 0; $i--) {
		$slide = $gPresentation.Slides.Item($i)
		if ($slide.SlideShowTransition.Hidden) {
			$slide.Delete()
		} else {
			foreach ($shape in $slide.Shapes) {
				Ungroup-Shape -in_shape $shape
			}
			Handle-Medias -in_slide $slide
		}
	}
}

$gCom = $null

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
