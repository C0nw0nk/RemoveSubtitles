@echo off & setLocal EnableDelayedExpansion

:: This script will Remove any unwanted subtitle codecs from media files in your library since vobsubs can be buggy and cause transcoding

:: Set the video formats to search for
set video_formats="-key1 .mkv"

:: These are the subtitle codecs you want to either log or remove from media files
:: Full List of codecs https://github.com/FFmpeg/FFmpeg/blob/master/libavformat/matroska.c#L67
:: set sub_codecs="-key1 arib_caption -key2 ass -key3 eia_608 -key4 hdmv_text_subtitle -key5 jacosub -key6 microdvd -key7 mov_text -key8 mpl2 -key9 pjs -key10 realtext -key11 sami -key12 srt -key13 ssa -key14 stl -key15 subrip -key16 subviewer -key17 subviewer1 -key18 text -key19 ttml -key20 vplayer -key21 webvtt -key22 dvb_subtitle -key23 dvb_teletext -key24 dvd_subtitle -key25 hdmv_pgs_subtitle -key26 xsub"
:: Remove pgs and vob subs only
set sub_codecs="-key1 hdmv_text_subtitle -key2 dvb_subtitle -key3 dvb_teletext -key4 dvd_subtitle -key5 hdmv_pgs_subtitle"

:: Directory to scan
:: Path format can be Network share or Drive name
:: example
:: set plex_folder="C:\path\Movies"
:: set plex_folder="\\NAS\FOLDER\Movies"
set plex_folder=""

:: Remove specified subtitle codecs from media files
:: 1 is to Remove
:: 0 is to Keep
set remove_subtitles_codecs=1

:: Log the output of the codec to a text file the file will be for example dvd_subtitle.txt or ass.txt
:: 1 is to Remove
:: 0 is to Keep
set log_sub_codec_output=1

:: Check for the .PlexCleaner sidecar file to skip already modified media
:: 1 is to skip
:: 0 is to modify all
set check_for_sidecar=0

:: Instead of just closing the window after our automated tasking we pause to view and check once your happy you can set this to 0
:: 1 enabled
:: 0 disabled
set pause_window=1

:: Wait number of seconds
:: 0 disabled
:: 60 = 60 seconds etc
set wait_interval=0

:: If you want this script to not exit once finished and after task complete / wait interval passed recheck plex folders in a loop
:: 1 enabled
:: 0 disabled
set looping=0

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

TITLE C0nw0nk - Plex/Emby Remove Subtitles codecs

:: Make script configurable via command line with arguements example
:: "C:\path\RemoveSubtitles.cmd" "\\NAS\path" "sub_codecs" "remove_subtitles_codecs" "log_sub_codec_output" "check_for_sidecar" "pause_window" "wait_interval" "looping" 2^>nul
:: Working example
:: "C:\path\RemoveSubtitles.cmd" "\\NAS\path" "-key1 dvb_subtitle -key2 dvb_teletext -key3 dvd_subtitle -key4 hdmv_pgs_subtitle" "1" "1" "0" "1" "0" "0" 2^>nul

if "%~1"=="" goto :script_arguments_not_defined
set plex_folder="%~1"
set sub_codecs="%~2"
set remove_subtitles_codecs=%~3
set log_sub_codec_output=%~4
set check_for_sidecar=%~5
set pause_window=%~6
set wait_interval=%~7
set looping=%~8
:script_arguments_not_defined

if "%plex_folder:"=%"=="" (
echo Input the Directory or Path you want to Remove Forced Subtitles flags on media items for example C:\path or you can use \\NAS\STORAGE\PATH
set /p "plex_folder="
)

set root_path="%~dp0"

if %PROCESSOR_ARCHITECTURE%==x86 (
	set programs_path=%ProgramFiles(x86)%
) else (
	set programs_path=%ProgramFiles%
)

goto :next_download
echo starting removing forced subtitle flags
:start_exe


:: Forced Subtitle code

set mkvtoolnix_path="%root_path:"=%mkvtoolnix\"
set "PATH=%PATH%;%mkvtoolnix_path:"=%"

:: set color code
for /F %%a in ('echo prompt $E ^| cmd') do (
  set "ESC=%%a"
)
:: end color code

:: enum codecs
set "codec_comd=aws iam create-group %sub_codecs:"=%"
for /F "tokens=3*" %%p in ("%codec_comd%") do set "codec_tokens=%%q"
set codec_n=0
set "key="
for %%a in (%codec_tokens:-=%) do (
	if not defined key (
		set key=%%a
	) else (
		set /A codec_n+=1
		set "codec_token[!codec_n!]=%%a"
		set "key="
	)
)
:: end enum codecs code

pushd "%plex_folder:"=%" 2>nul
if errorlevel 1 goto notdir
goto :isdir

:notdir

		setlocal DisableDelayedExpansion
		echo Direct file path not a directory "%plex_folder:"=%"
		for /f "delims=" %%F in ("%plex_folder:"=%") do set "directory_path_name=%%~dpnF"

		for /l %%i in (1,1,%codec_n%) do (
			echo Enumerating all !codec_token[%%i]! under "%%a"
			for /f %%b in ('%root_path:"=%win-x64\Tools\FfMpeg\bin\ffmpeg.exe -i "%plex_folder:"=%" 2^>^&1 ^| find /c /i "Subtitle: !codec_token[%%i]!"') do (
				if [%%b]==[0] (
					echo !ESC![32m "%%a" does not have !codec_token[%%i]! !ESC![0m
				) else (
					echo !ESC![31m "%%a" does have !codec_token[%%i]! !ESC![0m
					if [%log_sub_codec_output%]==[1] (
						echo "%%a" - "!codec_token[%%i]!" >> %root_path:"=%!codec_token[%%i]!.txt
					)
					if [%remove_subtitles_codecs%]==[1] (
						"%mkvtoolnix_path:"=%mkvmerge.exe" -o "%directory_path_name:"=%.tmp" --no-subtitles "%plex_folder:"=%"
						if errorlevel 1 (
							echo Warnings/errors generated during removing subtitles
						) else (
							echo Successfully removed subtitles
						)
						move /y "%directory_path_name:"=%.tmp" "%plex_folder:"=%"
					)
				)
			)
		)
		setLocal EnableDelayedExpansion

goto :end_script

:isdir

set "comd=aws iam create-group %video_formats:"=%"
for /F "tokens=3*" %%p in ("%comd%") do set "tokens=%%q"
set n=0
set "key="
for %%a in (%tokens:-=%) do (
	if not defined key (
		set key=%%a
	) else (
		set /A n+=1
		set "token[!n!]=%%a"
		set "key="
	)
)
for /l %%i in (1,1,%n%) do (
	echo Enumerating all !token[%%i]!s under "%plex_folder:"=%"
	for /r "%plex_folder:"=%" %%a in (*!token[%%i]!) do (
		for /l %%i in (1,1,%codec_n%) do (
			echo Enumerating all !codec_token[%%i]! under "%%a"
			rem echo filename %%~dpna fileextension %%~xa
			for /f %%b in ('%root_path:"=%win-x64\Tools\FfMpeg\bin\ffmpeg.exe -i "%%a" 2^>^&1 ^| find /c /i "Subtitle: !codec_token[%%i]!"') do (
				if [%%b]==[0] (
					echo !ESC![32m "%%a" does not have !codec_token[%%i]! !ESC![0m
				) else (
					echo !ESC![31m "%%a" does have !codec_token[%%i]! !ESC![0m
					if [%log_sub_codec_output%]==[1] (
						echo "%%a" - "!codec_token[%%i]!" >> %root_path:"=%!codec_token[%%i]!.txt
					)
					if [%remove_subtitles_codecs%]==[1] (
						"%mkvtoolnix_path:"=%mkvmerge.exe" -o "%%~dpna.tmp" --no-subtitles "%%a"
						if errorlevel 1 (
							echo Warnings/errors generated during removing subtitles
						) else (
							echo Successfully removed subtitles
						)
						move /y "%%~dpna.tmp" "%%a"
					)
				)
			)
		)
	)
)

::End Forced Subtitle code

goto :end_script

goto :next_download
:start_download
set downloadurl=%downloadurl: =%
FOR /f %%i IN ("%downloadurl:"=%") DO set filename="%%~ni"& set fileextension="%%~xi"
set downloadpath="%root_path:"=%%filename%%fileextension%"
(
echo Dim oXMLHTTP
echo Dim oStream
echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
echo If Not fso.FileExists^("%downloadpath:"=%"^) Then
echo Set oXMLHTTP = CreateObject^("MSXML2.ServerXMLHTTP.6.0"^)
echo oXMLHTTP.Open "GET", "%downloadurl:"=%", False
echo oXMLHTTP.SetRequestHeader "User-Agent", "Mozilla/5.0 ^(Windows NT 10.0; Win64; rv:51.0^) Gecko/20100101 Firefox/51.0"
echo oXMLHTTP.SetRequestHeader "Referer", "https://www.google.co.uk/"
echo oXMLHTTP.SetRequestHeader "DNT", "1"
echo oXMLHTTP.Send
echo If oXMLHTTP.Status = 200 Then
echo Set oStream = CreateObject^("ADODB.Stream"^)
echo oStream.Open
echo oStream.Type = 1
echo oStream.Write oXMLHTTP.responseBody
echo oStream.SaveToFile "%downloadpath:"=%"
echo oStream.Close
echo End If
echo End If
echo ZipFile="%downloadpath:"=%"
echo ExtractTo="%root_path:"=%"
echo ext = LCase^(fso.GetExtensionName^(ZipFile^)^)
echo If NOT fso.FolderExists^(ExtractTo^) Then
echo fso.CreateFolder^(ExtractTo^)
echo End If
echo Set app = CreateObject^("Shell.Application"^)
echo Sub ExtractByExtension^(fldr, ext, dst^)
echo For Each f In fldr.Items
echo If f.Type = "File folder" Then
echo ExtractByExtension f.GetFolder, ext, dst
echo End If
echo If instr^(f.Path, "\%file_name_to_extract%"^) ^> 0 Then
echo If fso.FileExists^(dst ^& f.Name ^& "." ^& LCase^(fso.GetExtensionName^(f.Path^)^) ^) Then
echo Else
echo call app.NameSpace^(dst^).CopyHere^(f.Path^, 4^+16^)
echo End If
echo End If
echo Next
echo End Sub
echo If instr^(ZipFile, "zip"^) ^> 0 Then
echo ExtractByExtension app.NameSpace^(ZipFile^), "exe", ExtractTo
echo End If
if [%file_name_to_extract%]==[*] echo set FilesInZip = app.NameSpace^(ZipFile^).items
if [%file_name_to_extract%]==[*] echo app.NameSpace^(ExtractTo^).CopyHere FilesInZip, 4
if [%delete_download%]==[1] echo fso.DeleteFile ZipFile
echo Set fso = Nothing
echo Set objShell = Nothing
)>"%root_path:"=%%~n0.vbs"
cscript //nologo "%root_path:"=%%~n0.vbs"
del "%root_path:"=%%~n0.vbs"
:next_download

if not exist "%root_path:"=%mkvtoolnix\mkvmerge.exe" (

winget install Microsoft.DotNet.DesktopRuntime.6 >nul
winget install Microsoft.DotNet.DesktopRuntime.7 >nul

if not defined plexcleaner_exe (
	set downloadurl=https://mkvtoolnix.download/windows/releases/79.0/mkvtoolnix-64-bit-79.0.7z
	set delete_download=0
	set plexcleaner_exe=true
	goto :start_download
)


if not exist "%programs_path%\WinRAR\winrar.exe" (
if not defined winrar_exe (
	if %PROCESSOR_ARCHITECTURE%==x86 (
		set downloadurl=https://www.rarlab.com/rar/winrar-x32-620b2.exe
	) else (
		set downloadurl=https://www.rarlab.com/rar/winrar-x64-620b2.exe
	)
	set delete_download=0
	set winrar_exe=true
	goto :start_download
)
start /wait %downloadpath% /s
del %downloadpath%
(
echo RAR registration data
echo WinRAR
echo Unlimited Company License
echo UID=4b914fb772c8376bf571
echo 6412212250f5711ad072cf351cfa39e2851192daf8a362681bbb1d
echo cd48da1d14d995f0bbf960fce6cb5ffde62890079861be57638717
echo 7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565
echo b41bcf56929486b8bcdac33d50ecf773996052598f1f556defffbd
echo 982fbe71e93df6b6346c37a3890f3c7edc65d7f5455470d13d1190
echo 6e6fb824bcf25f155547b5fc41901ad58c0992f570be1cf5608ba9
echo aef69d48c864bcd72d15163897773d314187f6a9af350808719796
)>"%programs_path%\WinRAR\rarreg.key"
) else (
	call ^"%programs_path%\WinRAR\winrar.exe^" x ^"%root_path:"=%mkvtoolnix-64-bit-79.0.7z^" ^"*^" ^"%root_path:"=%^"
	del "%root_path:"=%mkvtoolnix-64-bit-79.0.7z"
)

)

goto :start_exe
:end_script

if %pause_window% == 1 pause

if not %wait_interval% == 0 TIMEOUT /T %wait_interval%

if %looping% == 1 goto :start_exe

exit /b
