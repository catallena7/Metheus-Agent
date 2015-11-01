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

import util.Conf;
import util.Dao;

public class Agent {
	private static final Logger LOG = LogManager.getLogger(Agent.class);
	private static long intervalMSec = 60000L;
	public static String VERSION = "1.0.2";

	public long getIntervalMsec() {
		return intervalMSec;
	}

	@SuppressWarnings("static-access")
	public void setIntervalSec(long intervalSec) {
		LOG.info("IntervalSec=" + intervalSec);
		this.intervalMSec = intervalSec * 1000L;
	}

	public void init(Conf cf, String[] args) {
		if (args.length < 1) {
			LOG.error("please input config.xml as args");
			System.exit(0);
		}
		cf.setConfFile(args[0]);
	}

	public static void printSQLException(SQLException e) {
		while (e != null) {
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
		agent.init(cf, args);
		agent.setIntervalSec(cf.getSinglefValue("running_interval_second"));
		Dao dao = new Dao();
		Connection conn = null;
		Properties props = new Properties();
		props.put("user", "agent");
		props.put("password", "catallena7");
		String protocol = null;
		long keepdays = cf.getSinglefValue("keeping_days");
		int port = cf.getSinglefValue("port");
		try {
			protocol = "jdbc:derby://"
					+ InetAddress.getLocalHost().getHostName() + ":" + port
					+ "/";
			conn = DriverManager.getConnection(
					protocol + "derbyDB;create=true", props);
			conn.setAutoCommit(false);
			dao.checkTables(conn);
			dao.initData(conn, VERSION);
			PluginExecutor pe = new PluginExecutor(cf);
			long epNow = 0L;
			long sleepTime = 0L;
			long norTime = 0L;
			DateTime now = null;
			pe.setDB(conn, dao);
			pe.setPluginPathInterval(cf.getPluginInterval());
			pe.setPluginPathTable(cf.getPluginTables());
			pe.setPluginPathTimeout(cf.getPluginTimeout());
			pe.setPluginRunLimit(cf
					.getSinglefValue("plguin_running_error_limit"));
			int loopCnt = 0;
			dao.insertEvent(conn, "AG000", "INFO", "Agent was started");
			while (true) {
				if (dao.isUpdated(conn)) {
					LOG.error("Agent configuration updated - need to start for apply");
					dao.insertEvent(conn, "AG001", "INFO",
							"agent restart for config apply");
					System.exit(1);
				}
				dao.setLastUpdateTime(conn);
				now = new DateTime();
				epNow = now.getMillis();
				norTime = epNow - epNow % intervalMSec;
				pe.runPlugins(norTime);
				now = new DateTime();
				epNow = now.getMillis();
				sleepTime = intervalMSec - epNow % intervalMSec;
				norTime = epNow - sleepTime;
				if (loopCnt >= 1440 || loopCnt == 0) {
					dao.deleteData(conn, cf, keepdays);
					loopCnt = 1;
				}
				LOG.info(now + " epoch:" + epNow + " sleep:" + sleepTime);
				try {
					Thread.sleep(sleepTime);
					// Thread.sleep(10);
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
		} catch (UnknownHostException e) {
			LOG.fatal("Getting Hostname");
			System.exit(1);
		} catch (SQLException e) {
			printSQLException(e);
			System.exit(1);
		} finally {
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