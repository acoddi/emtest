CC = gcc
CFLAGS = -Wall -fPIC -I./include
LIBS = -lwiringPi -lpthread

# 라이브러리 파일이 들어갈 경로 지정
LIB_DIR = lib
LIB_TARGET = $(LIB_DIR)/libdevice.so

LIB_SRCS = src/led_thread_routine.c \
           src/buzzer_thread_routine.c \
           src/sensor_thread_routine.c \
           src/fnd_thread_routine.c

SERVER_SRCS = src/main.c src/server_thread.c
TARGET = main

all: $(LIB_DIR) $(LIB_TARGET) $(TARGET)

# lib 디렉토리가 없으면 생성
$(LIB_DIR):
	mkdir -p $(LIB_DIR)

# 동적 라이브러리 빌드 (lib 폴더 안에 생성)
$(LIB_TARGET): $(LIB_SRCS)
	$(CC) $(CFLAGS) -shared -o $(LIB_TARGET) $(LIB_SRCS) $(LIBS)

$(TARGET): $(SERVER_SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SERVER_SRCS) -L./$(LIB_DIR) -ldevice $(LIBS) -Wl,-rpath,./lib

clean:
	rm -f $(TARGET) $(LIB_TARGET)
	rm -rf $(LIB_DIR)