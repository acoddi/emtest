#define _POSIX_C_SOURCE 200809L

#include "common.h"
#include "device_control.h"

volatile int is_run = 1;
DeviceStatus global_status;

DeviceStatus *get_device_status()
{
    return &global_status;
}
void make_daemon();

int main(int argc, char **argv)
{
    // 1. 데몬화
    make_daemon();
    syslog(LOG_INFO, "Device Daemon Started");

    // 2. 데몬화 완료 후 하드웨어 및 뮤텍스 설정
    if (wiringPiSetup() == -1)
    {
        syslog(LOG_ERR, "wiringPiSetup Failed");
        return -1;
    }

    pthread_mutex_init(&global_status.lock, NULL);
    global_status.led_brightness = 0;
    global_status.fnd_value = 0;
    global_status.is_counting = 0;
    global_status.light_level = 0;

    // 3. 스레드 생성
    pthread_t t_led, t_buzzer, t_sensor, t_fnd, t_server;

    pthread_create(&t_led, NULL, led_thread_routine, &global_status);
    pthread_create(&t_buzzer, NULL, buzzer_thread_routine, &global_status);
    pthread_create(&t_sensor, NULL, sensor_thread_routine, &global_status);
    pthread_create(&t_fnd, NULL, fnd_thread_routine, &global_status);
    pthread_create(&t_server, NULL, server_thread, &global_status);

    syslog(LOG_INFO, "All threads created successfully");

    // 4. 백그라운드 무한 대기
    while (is_run)
    {
        sleep(10);
    }

    pthread_mutex_destroy(&global_status.lock);
    closelog();

    return 0;
}

// 데몬 프로세스를 만드는 함수
void make_daemon()
{
    pid_t pid;
    struct rlimit rl;
    struct sigaction sa;

    umask(0);

    if (getrlimit(RLIMIT_NOFILE, &rl) < 0)
        perror("getrlimit");

    if ((pid = fork()) < 0)
        exit(1);
    else if (pid != 0)
        exit(0); // 부모 종료

    setsid();

    // 터미널 관련 시그널 무시
    sa.sa_handler = SIG_IGN;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGHUP, &sa, NULL);

    if ((pid = fork()) < 0)
        exit(1);
    else if (pid != 0)
        exit(0); // 세션 리더 방지 위해 한 번 더 fork

    if (chdir("/") < 0)
        exit(1);

    // 모든 파일 디스크립터 닫기
    if (rl.rlim_max == RLIM_INFINITY)
        rl.rlim_max = 1024;
    for (int i = 0; i < rl.rlim_max; i++)
        close(i);

    // 표준 입출력을 /dev/null로 리다이렉트
    open("/dev/null", O_RDWR); // fd 0
    dup(0);                    // fd 1
    dup(0);                    // fd 2

    openlog("device_daemon", LOG_CONS, LOG_DAEMON);
}