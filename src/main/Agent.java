package main;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.joda.time.DateTime;

import util.Dao;

public class Agent {
	private static final Logger LOG= LogManager.getLogger(Agent.class);
	public static final long INTERVAL = 60000L;
	public void init(Conf cf, String[] args){
		if (args.length <1){
			LOG.error("please input configuration.xml with args");
			System.exit(0);
		}
		cf.setConfFile(args[0]);
	}
	public static void printSQLException(SQLException e){
		while (e != null){
            LOG.error("\n----- SQLException -----");
            LOG.error("  SQL State:  " + e.getSQLState());
            LOG.error("  Error Code: " + e.getErrorCode());
            LOG.error("  Message:    " + e.getMessage());
            e = e.getNextException();
        }
    }
	public static void main(String[] args) {
		Conf cf = new Conf();
		Agent agent = new Agent();
		agent.init(cf,args);
		Dao dao = new Dao();
		Connection conn = null;
		Properties props = new Properties();
        props.put("user", "agent");
        props.put("password", "catallena7");
        String protocol=null;
        long keepdays= cf.getKeepingDays();
		try {
			protocol = "jdbc:derby://"+InetAddress.getLocalHost().getHostName()+":32077/";
			conn = DriverManager.getConnection(protocol+"derbyDB;create=true", props);
			conn.setAutoCommit(false);
			dao.checkTables(conn);
			dao.initData(conn);
			PluginExecutor pe = new PluginExecutor(cf);
			long epNow=0L;
			long sleepTime=0L;
			long norTime=0L;
			DateTime now = null;
			pe.setDB(conn,dao);
			pe.setPluginPathInterval(cf.getPluginInterval());
			pe.setPluginPathTable(cf.getPluginTables());
			pe.setPluginPathTimeout(cf.getPluginTimeout());
			int loopCnt=0;
			while (true){ 
				if (dao.isUpdated(conn)){
					LOG.error("Agent configuration updated - restart to apply");
					System.exit(0);
				}
				now = new DateTime();
				epNow=now.getMillis();
				norTime = epNow-epNow%INTERVAL;
				pe.runPlugins(norTime);
				now = new DateTime();
				epNow = now.getMillis();
				sleepTime=INTERVAL-epNow%INTERVAL;
				norTime = epNow-sleepTime;
				if (loopCnt>=1440){
					dao.deleteData(conn,cf,keepdays);
					loopCnt=0;
				}
				LOG.info(now+" epoch:"+epNow+" sleep:"+sleepTime);
				try {
					Thread.sleep(sleepTime);
					//Thread.sleep(10);
				}catch (InterruptedException e){
					e.printStackTrace();
				}
			}
		}catch (UnknownHostException e) {
			LOG.fatal("Getting Hostname");
			System.exit(0);
		}catch (SQLException e) {
			printSQLException(e);
			System.exit(0);
		}finally {
            try {
                if (conn != null) {
                    conn.close();
                    conn = null;
                }
            } catch (SQLException e) {
                printSQLException(e);
            }
        }
	}
}