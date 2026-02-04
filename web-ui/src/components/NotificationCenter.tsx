import React, { useEffect } from 'react'
import { useAppStore } from '@stores/appStore'
import { Notification } from '@types'

export default function NotificationCenter() {
  const notifications = useAppStore((state) => state.notifications)
  const removeNotification = useAppStore((state) => state.removeNotification)

  return (
    <div className="fixed top-4 right-4 space-y-2 z-50">
      {notifications.map((notification) => (
        <NotificationItem
          key={notification.id}
          notification={notification}
          onClose={() => removeNotification(notification.id)}
        />
      ))}
    </div>
  )
}

interface NotificationItemProps {
  notification: Notification
  onClose: () => void
}

function NotificationItem({ notification, onClose }: NotificationItemProps) {
  useEffect(() => {
    if (notification.duration) {
      const timer = setTimeout(onClose, notification.duration)
      return () => clearTimeout(timer)
    }
  }, [notification.duration, onClose])

  const bgColor = {
    success: 'bg-green-50 border-green-200',
    error: 'bg-red-50 border-red-200',
    info: 'bg-blue-50 border-blue-200',
    warning: 'bg-yellow-50 border-yellow-200',
  }[notification.type]

  const textColor = {
    success: 'text-green-800',
    error: 'text-red-800',
    info: 'text-blue-800',
    warning: 'text-yellow-800',
  }[notification.type]

  const icon = {
    success: '✓',
    error: '✕',
    info: 'ℹ',
    warning: '⚠',
  }[notification.type]

  return (
    <div className={`${bgColor} border rounded-lg p-4 flex items-start gap-3`}>
      <span className={`${textColor} font-bold text-lg`}>{icon}</span>
      <div className="flex-1">
        <p className={`${textColor} text-sm`}>{notification.message}</p>
      </div>
      <button
        onClick={onClose}
        className={`${textColor} hover:opacity-70 text-lg font-bold`}
      >
        ✕
      </button>
    </div>
  )
}
