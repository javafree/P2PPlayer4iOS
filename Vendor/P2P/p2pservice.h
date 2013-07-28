#ifndef __KEVIN__P2PSERVICE__H__
#define __KEVIN__P2PSERVICE__H__

#include <stdint.h>

typedef char            TCHAR;
typedef unsigned char   BYTE;
typedef unsigned long   DWORD;

#define __int64 long long

#define MAX_PATH 260
#define MAX_URL_LEN 1024

/* defines and error codes*/

enum ErrorCode
{
	ERROR_SUCCESS     =  0,
	ERROR_PARAM       = -1,
	ERROR_HANDLE      = -2,
	ERROR_UNKONWN     = -3,
	ERROR_LINK        = -4,
	ERROR_BUFFER      = -5,
	ERROR_NOT_FOUND   = -6,
	ERROR_CREATE_FAIL = -7,
	ERROR_SHUTDOWN    = -8,
	ERROR_STREAM_EXIST= -9,
	ERROR_READ_OVERSTEP=-10,
};

enum  TASK_CODE
{
	TS_NOITEM = 0,
	TS_ERROR,
	TS_PAUSE,
	TS_CONNECT,
	TS_DOWNLOAD,
	TS_COMPLETE,
	TS_TIMEOUT
}; 

enum  FAIL_CODE
{
	FC_NOERROR = 0,
	FC_TIME_OUT,
	FC_DISK_SPACE,		// 磁盘空间不足。此时 nTotalSize 是总计需要的字节数
	FC_FILE_ERROR,		// 文件写入失败。例如文件名非法，等。
	FC_SOURCE_FAIL,	// 资源失效
	FC_ALREADY_EXIST,  // p2p任务重复
	FC_NOT_SUPPORT,     // 不支持的协议
	FC_RENAME_FAIL,      // 改名失败
	FC_FORBIDDEN         // 非法禁止
};
 
enum param_flag
{
	eTaskParamForceNewDownload = 0x00010000,
	eTaskParamCacheToFile      = 0x00020000,
	eTaskParamSplitFile        = 0x00030000,
	eTaskParamCacheMemory      = 0x00040000,
};

enum param_type
{
	eTaskUrlTrans = 0x00000001,
};

/*  data structure used */

typedef void* task_handle_t;

typedef struct task_param_s
{
	char* url;
	char* refer;
	char* path;
	char* filename;
	unsigned int flag;
	unsigned int opt;
} p2p_task_param_t;

typedef struct task_info_s
{
	int state; 
	int error;
	uint64_t filesize;
	uint64_t downloaded;
	int downspeed;
	int upspeed;
	int using_peers;
	int total_peers;
	int seeder_peers;
	int ndiskfiles;
	uint64_t uploaded;
	TCHAR szFilename[MAX_PATH];
} p2p_task_info_t;

typedef struct task_stat_s
{
	uint64_t down_dup;
	uint64_t short_win;
	uint64_t long_win;
	uint64_t read_pos;
	uint64_t win_pos;
	uint64_t unfinish_pos;
	uint8_t  diskfiles;
	uint8_t  is_playing;
	uint8_t  reserved[984];
} p2p_task_stat_t;

typedef struct url_info_s
{
	BYTE byFid[20]; // 目前只用了16字节（MD5）
	uint64_t nFileSize;
	TCHAR szFilename[MAX_PATH];
} p2p_url_info_t;

#define task_param_t p2p_task_param_t
#define task_stat_t p2p_task_stat_t
#define url_info_t p2p_url_info_t
#define task_info_t p2p_task_info_t
#define task_stat_t p2p_task_stat_t

#ifdef __cplusplus 
extern "C" {
#endif

/* initialize and uninitialize */


int p2pservice_init(int node_type, bool upload_to_normal_peer);

int p2pservice_destroy();

/* task management */

int p2pservice_task_create( p2p_task_param_t* param, task_handle_t* h );

int p2pservice_task_start( task_handle_t h );

int p2pservice_task_stop( task_handle_t h );

int p2pservice_task_destroy( task_handle_t h );

int p2pservice_task_info( task_handle_t h, task_info_t* inf);

int p2pservice_task_stat( task_handle_t h, p2p_task_stat_t* stat);

int p2pservice_get_redirect(task_handle_t h, TCHAR* szURL);

int p2pservice_parse_url(TCHAR* szURL, p2p_url_info_t* pInfo);

int p2pservice_set_network_status(bool bEnable);

/* for player */

int p2pservice_read(task_handle_t h, unsigned __int64 nOffset, char* pBuffer, unsigned __int64 nToRead, bool bMove);
int p2pservice_read_file(const char* szFileName, unsigned __int64 nFileSize, unsigned __int64 nOffset, char* pBuffer, unsigned __int64 nToRead);

int p2pservice_add_emergency_range(task_handle_t h, unsigned __int64 nBegin, unsigned __int64 nEnd);

int p2pservice_set_priority_window(task_handle_t h, unsigned __int64 nShortBufLen, unsigned __int64 nLongBufLen);

int p2pservice_get_block_info(task_handle_t h, char* pBuffer, unsigned __int64 nToRead);

int p2pservice_set_cache_size(unsigned int nCacheSize);

int p2pservice_set_playing(task_handle_t h, bool bPlaying);

int p2psevice_set_media_time(task_handle_t h, unsigned int nMediaTimeSecond);

int p2pservice_set_task_cache_size(task_handle_t h, unsigned int nCacheSize);

int p2pservice_set_bitrate(task_handle_t h, unsigned int nBitRate);

/* fid calculate */
int p2pservice_file_id(char* file, char* sz_fid);

int p2pservice_report_url(char* sz_fid, char* url);

/* service setting */

int p2pservice_set_local_port(unsigned short port, unsigned short retry_zone/* = 100*/);

int p2pservice_change_peer(task_handle_t h, unsigned __int64 uid, unsigned char node_type, DWORD ip, unsigned short port);

int p2pservice_pause_upload();

int p2pservice_get_peer_count(task_handle_t h);

int p2pservice_delete_file(const char* szFilePath, const char* szFileName, unsigned __int64 nFileSize);

int p2pservice_delete_dir(const char* szFilePath);

int p2pservice_file_exist(const char* szFilePath, const char* szFileName, unsigned __int64 nFileSize);

int p2pservice_set_speed_limit(unsigned int nSpeedLimit);

int p2pservice_set_task_speed_limit(task_handle_t h, unsigned int nSpeedLimit);

int p2pservice_set_log_level(unsigned int nLevel);

int p2pservice_get_block_size(task_handle_t h);

int p2pservice_set_deviceid(const char* szDeviceID);

/* for test */

unsigned p2pservice_crc32(char* pBuffer, unsigned int nLen);

int p2pservice_set_index(task_handle_t h, unsigned __int64 nBegin, unsigned __int64 nEnd);

int p2pservice_is_range_completed(task_handle_t h, unsigned __int64 nBegin, unsigned __int64 nEnd);

#ifdef __cplusplus
};
#endif

#endif /* __KEVIN__P2PSERVICE__H__ */


