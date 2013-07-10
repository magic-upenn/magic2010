#/***************************************************************************
# * Humanistic Robotics VSC Interface Library                               *
# * Version 1.0                                                             *
# * Copyright 2013, Humanistic Robotics, Inc                                *
# ***************************************************************************/
#/*
# * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# * POSSIBILITY OF SUCH DAMAGE.
# */

CC = gcc
CFLAGS  = -g -Wall

DRIVERS = ../SerialInterface.c ../VehicleInterface.c 
SRCS = vsc_tutorial_1.c vsc_tutorial_2.c vsc_tutorial_3.c vsc_tutorial_4.c

all: clean $(SRCS:.c=)

.c:
	$(CC) $(CFLAGS) $< $(DRIVERS) -o $@ -I../include -lrt

clean:
	$(RM) $(SRCS:.c=) 

