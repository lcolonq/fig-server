module Fig.Web.DB where

import Control.Error.Util (hush)

import qualified Database.Redis as Redis

import Fig.Prelude
import Fig.Web.Utils

connect :: MonadIO m => Config -> m Redis.Connection
connect cfg = liftIO $ Redis.checkedConnect Redis.defaultConnectInfo
  { Redis.connectHost = unpack cfg.dbHost
  }

get :: MonadIO m => Redis.Connection -> ByteString -> m (Maybe ByteString)
get c key = liftIO $ Redis.runRedis c do
  v <- Redis.get key
  pure . join $ hush v

incr :: MonadIO m => Redis.Connection -> ByteString -> m ()
incr c key = liftIO $ Redis.runRedis c do
  void $ Redis.incr key

decr :: MonadIO m => Redis.Connection -> ByteString -> m ()
decr c key = liftIO $ Redis.runRedis c do
  void $ Redis.decr key

hget :: MonadIO m => Redis.Connection -> ByteString -> ByteString -> m (Maybe ByteString)
hget c key hkey = liftIO $ Redis.runRedis c do
  v <- Redis.hget key hkey
  pure . join $ hush v

hkeys :: MonadIO m => Redis.Connection -> ByteString -> m (Maybe [ByteString])
hkeys c key = liftIO $ Redis.runRedis c do
  hush <$> Redis.hkeys key

hvals :: MonadIO m => Redis.Connection -> ByteString -> m (Maybe [ByteString])
hvals c key = liftIO $ Redis.runRedis c do
  hush <$> Redis.hvals key

sadd :: MonadIO m => Redis.Connection -> ByteString -> [ByteString] -> m ()
sadd c key skeys = liftIO $ Redis.runRedis c do
  _ <- Redis.sadd key skeys
  pure ()

srem :: MonadIO m => Redis.Connection -> ByteString -> [ByteString] -> m ()
srem c key skeys = liftIO $ Redis.runRedis c do
  _ <- Redis.srem key skeys
  pure ()

smembers :: MonadIO m => Redis.Connection -> ByteString -> m (Maybe [ByteString])
smembers c key = liftIO $ Redis.runRedis c do
  hush <$> Redis.smembers key

sismember :: MonadIO m => Redis.Connection -> ByteString -> ByteString -> m Bool
sismember c key skey = liftIO $ Redis.runRedis c do
  Redis.sismember key skey >>= hush >>> \case
    Just x -> pure x
    Nothing -> pure False

lpop :: MonadIO m => Redis.Connection -> ByteString -> m (Maybe ByteString)
lpop c key = liftIO $ Redis.runRedis c do
  join . hush <$> Redis.lpop key

rpush :: MonadIO m => Redis.Connection -> ByteString -> ByteString -> m ()
rpush c key val = liftIO $ Redis.runRedis c do
  _ <- Redis.rpush key [val]
  pure ()
