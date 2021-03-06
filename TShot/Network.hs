module TShot.Network
    (
      downloadFile,
      getThumbsByID,
      getVideosByHash,
      fetchVideo,
      fetchThumnail
    ) where

import TShot.Type
import TShot.Parse.JSON

import System.IO (openBinaryFile, hPutStr, hClose, IOMode(..))
import Network.HTTP

tsHost :: Link
tsHost = "http://i.vod.xunlei.com/"

tShotUserAgent =
    "Mozilla/5.0 (X11; Linux x86_64; rv:19.0) Gecko/20100101 Firefox/19.0"

idLink :: HashCode -> Link
idLink hash = tsHost ++ "/req_subBT/info_hash/" ++ hash ++ "/req_num/2000/req_offset/0/"

imageLink :: HashCode -> VideoID -> Link
imageLink hash i = tsHost ++ "req_screensnpt_url?userid=5&url=bt://" ++ hash ++ "/" ++ (show i)


agentGetRequest :: String -> Request_String
agentGetRequest = replaceHeader HdrUserAgent tShotUserAgent . getRequest 

downloadFile :: Link -> FilePath -> IO ()
downloadFile link fn = do 
	rsp <- simpleHTTP $ agentGetRequest link
	body <- getResponseBody rsp
	fh <- openBinaryFile fn WriteMode
	hPutStr fh body
	hClose fh

fetchThumnail :: Thumbnail -> FilePath -> IO ()
fetchThumnail thumb = downloadFile (tbLink thumb)

fetchVideo :: FilePath ->(VideoID -> String -> Int -> String) -> Video -> IO ()
fetchVideo dir fname video = mapM_ fetch (zip [1..] thumbs)
	where fetch (i, t) = fetchThumnail t $ dir ++ "/" ++ fname id name i
	      thumbs = videoThumbs video
	      id = videoID video
	      name = videoName video

-- getThumbsByID:
getThumbsByID :: HashCode -> VideoID -> IO [Thumbnail]
getThumbsByID hash i = do
	rsp <- simpleHTTP $ agentGetRequest $ imageLink hash i
	body <- getResponseBody rsp
	return $ thumbsFromJSON body

-- getVideosByHash: 
getVideosByHash :: HashCode -> IO [Video]
getVideosByHash hash = do
  rsp <- simpleHTTP $ agentGetRequest $ idLink hash
  body <- getResponseBody rsp
  mapM pVideo $ videosInfoFromJSON body
  where pVideo (id, name) = do 
		thumbs <- getThumbsByID hash id
		return $ Video id name thumbs
