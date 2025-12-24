CC = gcc
CFLAGS = -Wall -fPIC -I./include
# 라이브러리 제작에 필요한 하드웨어 관련 라이브러리
LIB_LIBS = -lwiringPi -lpthread
# 메인 프로그램(데몬) 빌드에 필요한 라이브러리 (dlopen을 위해 -ldl 필수)
MAIN_LIBS = -lwiringPi -ldl -lpthread -rdynamic

# 디렉토리 설정
LIB_DIR = lib
SRC_DIR = src

# 타겟 설정
LIB_TARGET = $(LIB_DIR)/libdevice_control.so
TARGET = maintest

# 소스 파일 설정
# main.c에서 dlsym으로 불러올 함수들이 포함된 소스들
LIB_SRCS = $(SRC_DIR)/led_thread_routine.c \
           $(SRC_DIR)/buzzer_thread_routine.c \
           $(SRC_DIR)/sensor_thread_routine.c \
           $(SRC_DIR)/fnd_thread_routine.c \
           $(SRC_DIR)/server_thread.c

# 메인 데몬 소스
MAIN_SRCS = $(SRC_DIR)/main.c

all: $(LIB_DIR) $(LIB_TARGET) $(TARGET)

# 1. lib 디렉토리 생성
$(LIB_DIR):
	mkdir -p $(LIB_DIR)

# 2. 공유 라이브러리(.so) 빌드
$(LIB_TARGET): $(LIB_SRCS)
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LIB_LIBS)

# 3. 메인 데몬 빌드
$(TARGET): $(MAIN_SRCS)
	$(CC) $(CFLAGS) -o $@ $^ $(MAIN_LIBS)

clean:
	rm -f $(TARGET)
	rm -rf $(LIB_DIR)

.PHONY: all clean