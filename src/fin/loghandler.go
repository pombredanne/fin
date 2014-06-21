// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"log"
	"net/http"
	"time"
)

type LogResponseWriter struct {
	http.ResponseWriter
	Status int
}

func (w *LogResponseWriter) WriteHeader(status int) {
	w.Status = status
	w.ResponseWriter.WriteHeader(status)
}
func (w *LogResponseWriter) Write(data []byte) (int, error) {
	if w.Status == 0 {
		w.Status = 200
	}
	return w.ResponseWriter.Write(data)
}
func (w *LogResponseWriter) Flush() {
	w.ResponseWriter.(http.Flusher).Flush()
}

func LogHandler(log *log.Logger, handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Save URL before running the request, as http.StripPrefix modifies it.
		url := r.URL.Path
		logw := &LogResponseWriter{ResponseWriter: w}
		start := time.Now()
		handler.ServeHTTP(logw, r)
		end := time.Now()
		dt := end.Sub(start)
		log.Printf("%s %s %s %d %dms", r.RemoteAddr, r.Method, url, logw.Status, dt/time.Millisecond)
	})
}
